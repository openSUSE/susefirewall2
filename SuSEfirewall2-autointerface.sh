#!/bin/bash
#
# SuSEfirewall2-autointerface.sh - helper script for SuSEfirewall2
# Copyright (C) 2004 SUSE Linux AG
#
# Author: Ludwig Nussel
# 
# Please send feedback via http://www.suse.de/feedback
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# determine which network devices are internal and which are external
#
# The external device is always the one where the default route points at. If
# there is no default route, then there is also no external device.
#
# Active devices except the external one are considered as candidates for
# internal. Devices that are configured for pppoe in
# /etc/sysconfig/network/ifcfg-dsl* are removed from the active list. If only
# one device is left after that filter, it's considered as internal.
#
# => only one external and one internal possible
# => if you only have one device with no default route it's internal
#
# All packets that arrive on devices that are neither internal nor external
# will be dropped by the firewall

# print the device where the default route points at
get_default_route_dev()
{
	while read line; do
		set -- $line
		[ "$1" != default ] && continue;
		# interface name comes after a "dev" token
		while [ "$1" != dev -a $# -gt 0 ]; do shift; done
		if [ "$1" = dev ]; then
			echo $2
			break;
		fi
	done < <(ip route show)
}

# print active interfaces except lo
get_active_interfaces()
{
	while read line; do
		set -- $line
		case "$3" in
			*UP*)
				dev=${2%%:}
				[ "$dev" != "lo" ] && echo $dev
			;;
		esac
	done < <(ip -o link show)
}

# first parameter is device to filter from rest of arguments
filter_one_dev()
{
	filter="$1"
	shift
	if [ -z "$filter" ]; then
		echo "$@"
		return;
	fi
	for i in "$@"; do
		[ "$filter" = "$i" ] && continue
		echo $i
	done
}

# filter devices for which a pppoe link is configured. exit with status 1 if
# more than one device is left
filter_pppoe_devs()
{
	for i in /etc/sysconfig/network/ifcfg-dsl*; do
		. $i
		[ -z "$DEVICE" -o $PPPMODE != pppoe ] && continue
		if [ -x "/sbin/getcfg-interface" ] && ! ip link show dev "$DEVICE" > /dev/null 2>&1; then
			DEVICE=`/sbin/getcfg-interface "$DEVICE"` || continue
		fi
		set -- `filter_one_dev "$DEVICE" "$@"`
	done
	echo "$@"
	[ "$#" -gt 1 ] && return 1
	return 0
}

shopt -s nullglob

internal=
external=`get_default_route_dev`

# all active devices
active=`get_active_interfaces`

# active devices except the default route device
filtered=`filter_one_dev "$external" $active`

# active devices minus pppoe devices
filtered2=`filter_pppoe_devs $filtered`
[ "$?" = 0 ] && internal=$filtered2

echo "External: $external"
echo "Internal: $internal"

#echo "Active: $active"
#echo "Filtered: $filtered"
#echo "Filtered2: $filtered2"
