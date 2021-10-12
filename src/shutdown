##!/bin/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC3057

PATH="$PATH:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin" # traditonal linux paths
PATH="$PATH:/usr/lib/systemd" # systemd libexec components normally hidden from PATH
PATH="$PATH:/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin" # NixOS standard path
PATH="$PATH:/run/current-system/sw/lib/systemd" # systemd libexec components in NixOS

# Note: Busybox has a shutdown implementations example in its sources that bills itself as:
# "Replaces traditional overdesigned shutdown mechanism". It's way overdesigned.

# TODO: Support kexec?
# TODO: More compatibility with sysvinit or systemd shutdown commands
# TODO: 'nologin' support
# http://manpages.ubuntu.com/manpages/bionic/man8/shutdown.8.html
# https://manpages.debian.org/testing/sysvinit-core/shutdown.8.en.html
# https://github.com/slicer69/sysvinit/blob/master/sysvinit/trunk/src/shutdown.c

help=\
" 
	$0 [--help] [-h/--halt] [-P/--poweroff] [-r/-reboot] [-n] [-f] TIME WALL
	
	Will call either halt, poweroff, or reboot with a delay and [-n/-f] options.
	Defaults to 'poweroff'.

	-n Do not sync
	-f Force (don't go through init)

	TIME takes the following formats:
		s      Wait for s seconds
		+m     Wait for m minutes
		+hh:mm Wait for h hours and m minutes
		hh:mm  Wait until this time
		now    Don't wait at all
	Defaults to 'now'

	WALL message may be overridden.
"

parse_time() {
	result=$(echo "${1}" | awk -F: '\
		/^[0-9]+$/ { print ($1) } 
		/^\+[0-9]+$/ { print ($1*60) } 
		/^\+[0-9]+:[0-9]+$/ { print ($1*360+$2*60) } \
		/^[0-9]+:[0-9]+$/ { t=(mktime(strftime("%Y %m %d",systime())" "$1" "$2" 00")-systime()); if (t < 0) { print (t+86400) } else { print t } } \
		/^now$/ { print 0 } \
		')
	if [ "${result}" ]; then
		seconds="${result}"
	else
		return 1
	fi
}

# Defaults
extra_args=""
seconds="0"
cmd="poweroff"
wall_message=""

while [ $# -gt 0 ]; do
	case "$1" in
		--help)
			echo "${help}"
			exit 0;;
		-H|--halt)
			for_wall="for system halt"
			cmd="halt";;
		-h)
			if [ "${cmd}" != "halt" ]; then
				cmd="poweroff"
			fi;;
		-P|--poweroff)
			for_wall="to maintenance mode"
			cmd="poweroff";;
		-r|--reboot)
			for_wall="for reboot"
			cmd="reboot";;
		-n)
			extra_args="${extra_args} -n";;
		-f)
			extra_args="${extra_args} -f";;
		-c)
			pkill shutdown
			exit 0;;
		*)
			if ! parse_time "${1}"; then
				wall_message="${1}"
			fi
	esac
	shift
done

# The system is going down %s NOW!
# The system is going DOWN %s in %d minute%s

if [ -z "${wall_message}" ]; then
	if [ "${seconds}" = "0" ]; then
		wall_message="The system is going down ${for_wall} NOW!"
	else
		wall_message="The system is going DOWN ${for_wall} in ${seconds} seconds!"
	fi
fi

echo "${wall_message}" | wall
#echo "${cmd} -d ${seconds}${extra_args}"
eval "${cmd} -d ${seconds}${extra_args}"

