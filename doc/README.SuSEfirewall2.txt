SuSEfirewall2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Table of Contents

1. Introduction
2. Quickstart

    2.1. YaST2 firewall module
    2.2. Manual configuration

3. Some words about security
4. Source Code
5. Reporting bugs
6. Links
7. Author

1. Introduction

SuSEfirewall2 is a shell script wrapper for the Linux firewall setup tool
(iptables). It's controlled by a human readable configuration file.

Main features of SuSEfirewall2:

  • sets up secure filter rules by default

  • easy to configure

  • requires only a small configuration effort

  • zone based setup. Interfaces are grouped into zones

  • supports an arbitrary number of zones

  • supports forwarding, masquerading, port redirection

  • supports RPC services with dynamically assigned ports

  • allows special treatment of IPsec packets

  • IPv6 support

  • allows insertion of custom rules through hooks

  • graphical zone switcher applet for desktop use

2. Quickstart

2.1. YaST2 firewall module

The YaST2 firewall module is the recommended tool for configuring
SuSEfirewall2. It offers the most common features with a nice user interface
and help texts. It also takes care of proper activation of the init scripts.

2.2. Manual configuration

Enable the SuSEfirewall2 boot scripts:

chkconfig SuSEfirewall2_init on

chkconfig SuSEfirewall2_setup on

Edit /etc/sysconfig/SuSEfirewall2 with your favorite editor. Read the commented
lines carefully. They give you many hints and tips for the configuration. You
need to at least add one network interface to FW_DEV_EXT for SuSEfirewall2 to
do anything. If you are stuck or need additional hints, take a look at EXAMPLES
file in /usr/share/doc/packages/SuSEfirewall2

3. Some words about security

SuSEfirewall2 is a frontend for iptables which sets up kernel packet filters,
nothing more and nothing less. This means that you are not automatically
protected from all security hazards by using SuSEfirewall2. To minimize
security risks on a networked system obey the following rules:

  • Run only those services you actually need. Think twice before opening them
    to the internet.

  • Use only software which has been designed with security in mind (like
    postfix, vsftpd, OpenSSH).

  • Do not expose services that are designed for use in a LAN to the internet
    (like e.g. samba, NFS, cups).

  • Do not run untrusted software. (philosophical question, can you trust SUSE
    or any other software distributor?)

  • Run YaST Online Update on a regular basis or enable it's automatic mode to
    get the latest security fixes.

  • Subscribe to the opensuse-security-announce mailinglist to keep yourself
    informed about new and upcoming security issues.

  • If you are using a server as a firewall/bastion host to the internet for an
    internal network, try to run proxy services for everything and disable
    routing on that machine.

  • If you run DNS on the firewall: disable untrusted zone transfers and either
    don't allow access to it from the internet or run it split-brained.

  • Check your log files regularly for unusual entries.

4. Source Code

Source code is available at Github

5. Reporting bugs

Report any problems via Bugzilla. For discussion about SuSEfirewall2 join the
opensuse-security mailinglist.

6. Links

Examples

Frequently Asked Questions

7. Author

SuSEfirewall2 was originally created by Marc Heuse. Most of it got rewritten
and enhanced by it's current maintainer Ludwig Nussel

