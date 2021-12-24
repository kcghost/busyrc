#!/bin/busybox ash

@path_include@

iface="$1"
action="$2"

PATH=""

case $action in
	up)
		udhcpc -i ${iface} -n -q -S -s /etc/busyrc/udhcpc.script
		;;
	down)
		# TODO: Is anything needed here?
		;;
	*)
		echo "Unknown ifplug command ${action}!" >&2
		;;
esac

