#!/usr/bin/python3

from __future__ import print_function
import os, sys
import argparse
import tempfile
import datetime
import shutil
import subprocess

try:
	import paramiko
	# there's a plethora of issues in paramiko regarding host key
	# selection like found in this PR:
	# https://github.com/paramiko/paramiko/issues/350
	#
	# it seems paramiko uses different preferences than openssh itself.
	# openssh uses ecdsa while paramiko sticks to rsa. rsa keys are not in
	# known hosts, leading to "not found in known_hosts" errors which are
	# confusing.
	#
	# current Leap 42.3 version still doesn't fix this. this here is hacky
	# workaround that doesn't require changing the known hosts policy to
	# auto-add.
	pks = paramiko.transport.Transport._preferred_keys
	paramiko.transport.Transport._preferred_keys = ('ecdsa-sha2-nistp256',) + pks
except ImportError:
	print("Failed to load paramiko module.\n"
			"Try installing python3-paramiko\n",
			file = sys.stderr,
			end = '')
	sys.exit(1)

# this script provides some minimum regression testing of sf2 changes.

class SshFailed(Exception):

	def __init__(self, host, cmd, ret):

		super(SshFailed, self).__init__(
			"Failed to run {} on {}: Exited with {}".format(
				cmd, host, ret
			)
		)

		self.m_ret = ret

class RegTest(object):

	def __init__(self):

		self.m_parser = argparse.ArgumentParser(
			description = "Regression testing between different SuSEfirewall2 versions. This script can compare two RPM versions of SuSEfirewall2. It aims at interactive evaluation of the differences in rule sets.",
		)

		self.m_parser.add_argument(
			"--host",
			help = "The remote host to test on",
			required = True
		)

		self.m_parser.add_argument(
			"--rpm",
			help = "The new RPM with changes to compare against",
			required = True
		)

		self.m_parser.add_argument(
			"-f", "--force",
			help = "Avoid asking 'unnecessary' questions.",
			action = 'store_true'
		)

		self.m_sf2_label = "SuSEfirewall2"
		self.m_is_systemd = None

	def prepareHostDir(self):

		self.m_host_dir = os.path.join(
			tempfile.gettempdir(),
			'.'.join(["sf2", self.m_args.host])
		)

		if os.path.exists(self.m_host_dir):

			if not self.m_args.force:
				self.ask(
					"Test directory {} already exists. Do you want to delete it?".format(self.m_host_dir)
				)

			shutil.rmtree(self.m_host_dir)

		os.makedirs(self.m_host_dir)
		print("Using", self.m_host_dir, "for test data")

	def isSystemD(self):
		"""Returns whether the remote host runs SystemD. Otherwise
		it's sysv init."""

		if self.m_is_systemd != None:
			return self.m_is_systemd

		try:
			self.runRemote("pgrep systemd", silent = True)
			self.m_is_systemd = True
		except SshFailed:
			self.m_is_systemd = False

		return self.m_is_systemd

	def isSysV(self):
		return not self.isSystemD()

	def ask(self, q):

		print(q)

		answer = None
		while answer not in ("y", "n", "yes", "no"):
			print("(y/n)? ", end = '')
			sys.stdout.flush()
			answer = sys.stdin.readline()

			if not answer:
				print("Aborted by user")
				sys.exit(3)

			answer = answer.lower().strip()

		if answer not in ("y", "yes"):
			print("Not continuing operation")
			sys.exit(3)

	def interactiveWait(self, msg):

		print(msg)
		print("ENTER to continue")
		sys.stdout.flush()
		nothing = sys.stdin.readline()

	def invokeDiff(self, old, new):

		subprocess.call(
			[
				"/usr/bin/vimdiff",
				old,
				new
			],
			shell = False,
			close_fds = True
		)

	def checkRemoteStatus(self, cmd, out):
		"""Checks the exist status of a remote command via the given
		stdout stream."""
		ret = out.channel.recv_exit_status()

		if ret != 0:
			raise SshFailed(self.m_args.host, cmd, ret)

	def runRemote(self, cmd, silent = False):

		inp, out, err = self.m_client.exec_command(cmd)

		# TODO: this is not exactly safe against large amounts of
		# stderr appearing, because we're reading stdout first. This
		# might thus block forever.
		# paramiko's handling of I/O streams is quite strange, this is
		# the simplest "working" solution I came up with for the
		# moment. redirecting stderr to stdout would be a good
		# solution.
		for _file in out, err:
			self.readRemote(_file, silent = silent)

		self.checkRemoteStatus(cmd, out)

	def getRemoteOutput(self, cmd):

		inp, out, err = self.m_client.exec_command(cmd)

		# TODO: same as with runRemote()
		ret = out.read()

		self.readRemote(err)
		self.checkRemoteStatus(cmd, out)

		return ret.decode()

	def readRemote(self, _file, silent = False):

		while True:
			line = _file.readline()
			if not line:
				break

			if silent:
				continue
			print(self.m_args.host, ">> ", line.strip(), sep = '')

	def revertSF2(self):
		"""Reverts SF2 on the target host to the last known stable
		version via zypper."""

		print("Installing clean {} on {}".format(
			self.m_sf2_label,
			self.m_args.host
		))
		print()
		self.runRemote(
			"/usr/bin/zypper --non-interactive in -f {}".format(self.m_sf2_label)
		)
		print()

	def restartSF2(self):
		"""Restarts the firewall on the target host."""

		self.m_last_sf2_restart = self.getRemoteDate()
		if self.isSysV():
			self.m_last_sf2_logline = self.getRemoteOutput(
				"tail -n1 /var/log/messages"
			)
		print("Restarting firewall on {}".format(self.m_args.host))
		print()
		if self.isSystemD():
			self.runRemote("systemctl restart {}.service".format(
				self.m_sf2_label
			))
		else:
			self.runRemote("/etc/init.d/{}_setup restart".format(
				self.m_sf2_label
			))
		print()

	def connect(self):

		try:
			print("Connecting to {} via SSH".format(self.m_args.host))
			self.m_client = paramiko.client.SSHClient()
			self.m_client.load_system_host_keys()
			# this would auto-add unknown hosts, rather don't use
			# it except for testing (the test, that is! ;)
			#self.m_client.set_missing_host_key_policy(paramiko.WarningPolicy())
			self.m_client.connect(self.m_args.host, username="root")

			self.m_sftp = self.m_client.open_sftp()
		except Exception as e:
			print("Connection to {} failed:".format(self.m_args.host), e)
			sys.exit(1)

	def determineHostProps(self):

		if self.isSystemD():
			print("Remote host uses SystemD")
		else:
			print("Remote host uses SysV init")

	def getCurrentVersion(self):
		"""Returns the current version of the installed SF2 on the
		remote host."""

		info = self.getRemoteOutput(
			"zypper info {}".format(self.m_sf2_label)
		)

		for line in info.splitlines():

			if not line.startswith("Version"):
				continue

			parts = line.split()
			# on SLE-12 this is "Version     : ...."
			# on SLE-11 this is "Version: ...."
			return parts[1] if parts[1] != ":" else parts[2]

		raise Exception("Failed to determine currently installed SF2 version2")

	def fetchIptablesRules(self, target_dir):
		"""Fetches both, IPv4 and IPv6 table rules and saves them in
		the current test directory."""
		print("Fetching current iptables rules")
		print()

		for iptables in ("iptables", "ip6tables"):
			rules = self.getRemoteOutput("{} -S".format(iptables))
			outpath = os.path.join(target_dir, iptables + ".rules")

			print("Writing", outpath)
			with open(outpath, 'w') as out_fd:
				out_fd.write(rules)

		print()

	def uploadFile(self, which, whereto):

		self.m_sftp.put(which, whereto)

	def installNew(self):

		print("Uploading rpm")
		print()
		base = os.path.basename(self.m_args.rpm)
		rempath = os.path.join(tempfile.gettempdir(), base)
		self.uploadFile(self.m_args.rpm, rempath)
		print()

		if not self.m_args.force:
			self.ask(
				"The rpm in {} will now be installed on {}. "
				"Continue?".format(
					self.m_args.rpm,
					self.m_args.host
			))

		print("Installing {} on remote host".format(base))

		self.installRPM(rempath)

		print()

	def installRPM(self, rpm):
		
		# install RPMs directly via rpm is better than via zypper. the
		# latter complains about signatures and such
		self.runRemote("rpm -i --force --nodeps --replacepkgs {}".format(
			rpm
		))

	def getRemoteDate(self):
		"""Returns the remote date as a datetime object."""

		unixtime = self.getRemoteOutput("date +'%s'")

		return datetime.datetime.fromtimestamp(float(unixtime))

	def getSF2Log(self, target_dir):

		if self.isSystemD():
			log = self.getRemoteOutput(
				"journalctl -u {}.service -S '{}'".format(
					self.m_sf2_label,
					self.m_last_sf2_restart.strftime(
						"%Y-%m-%d %H:%M:%S"
					)
				)
			)
		else:
			parts = self.m_last_sf2_logline.split()
			date = ' '.join(parts[:3])
			log = self.getRemoteOutput(
				"sed -n '/^{}/,$p' /var/log/messages".format(
					date
				)
			)

		with open(os.path.join(target_dir, "log"), 'w') as log_fd:
			log_fd.write(log)

	def showLogs(self, old_dir, new_dir):

		self.interactiveWait("Showing diff of log output")

		self.invokeDiff(
			os.path.join(old_dir, "log"),
			os.path.join(new_dir, "log")
		)

		for rules in ("iptables", "ip6tables"):
			self.interactiveWait(
				"Showing diff of {} rules".format(rules)
			)
			rule_file = "{}.rules".format(rules)
			self.invokeDiff(
				os.path.join(old_dir, rule_file),
				os.path.join(new_dir, rule_file)
			)

	def run(self):

		self.m_args = self.m_parser.parse_args()

		self.prepareHostDir()
		self.connect()
		self.determineHostProps()

		if not self.m_args.force:
			self.ask("The {sf2} on {host} will be (re-)installed and restarted. "
				"Do you want to continue?".format(
					sf2 = self.m_sf2_label, host = self.m_args.host)
			)

		self.revertSF2()
		self.restartSF2()
		first_version = self.getCurrentVersion()
		first_version_dir = os.path.join(self.m_host_dir, first_version)
		os.makedirs(first_version_dir)
		os.symlink(
			first_version_dir,
			os.path.join(self.m_host_dir, "old")
		)

		self.fetchIptablesRules(first_version_dir)
		self.getSF2Log(first_version_dir)

		self.installNew()
		self.restartSF2()
		second_version = self.getCurrentVersion()
		if first_version == second_version:
			second_version += "-new"
		second_version_dir = os.path.join(self.m_host_dir, second_version)
		os.makedirs(second_version_dir)
		os.symlink(
			second_version_dir,
			os.path.join(self.m_host_dir, "new")
		)
		self.fetchIptablesRules(second_version_dir)
		self.getSF2Log(second_version_dir)

		# create a clean state again
		self.revertSF2()

		self.showLogs(first_version_dir, second_version_dir)

		print("You can find logs in")
		print("-", first_version_dir)
		print("-", second_version_dir)

regtest = RegTest()
regtest.run()
