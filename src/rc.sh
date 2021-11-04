#!/bin/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC3057
# ash supports string indexing just fine shellcheck!

# This file is executed on boot to initialize the system and can also be run by
# the user to start/stop daemons.

# Note: Preferable to use a busybox with:
# FEATURE_SH_STANDALONE, FEATURE_PREFER_APPLETS, FEATURE_SH_NOFORK
# In NixOS the shebang is automatically rewritten to use a busybox with these features (but not actually install it to PATH)
# Assume busybox ash shell features and prefer builtins or nofork applets

@path_include@

# Fallback Configuration Values, to be able to run even with a broken, deleted
# or outdated busyrc.conf:
DAEMONS=""
ENABLED="@syslogd @klogd"

UDEV="auto"
NETWORK_INTERFACE="eth0"
WIFI_INTERFACE="wlan0"
WAIT_POLLRATE="0.1"
WAIT_TRIES="30"
read -r HOSTNAME </etc/hostname

main() {
	# handle arguments
	case "$1" in
	init)
		on_boot;;
	shutdown)
		on_shutdown;;
	start|stop|restart)
		cmd="$1"
		shift
		for dmn in ${@:-${DAEMONS}}; do
			daemon "${cmd}" "${dmn}"
		done;;
	''|list)
		# list all daemons and their status
		for dmn in ${DAEMONS}; do
			daemon exists "${dmn}" || continue
			if daemon poll "${dmn}"; then
				echo_color 2 [X] "${dmn}"
			else
				echo_color 0 [ ] "${dmn}"
			fi
		done;;
	--version)
		echo busyrc 1.0;;
	*)
		self=$(basename "$0")
		echo "Usage: ${self} [--help] [--version] <action> [list of daemons]"
		echo
		echo "Actions:"
		echo "   ${self} list               shows status of all daemons (default action)"
		echo "   ${self} start [daemons]    starts daemons"
		echo "   ${self} stop [daemons]     stops daemons"
		echo "   ${self} restart [daemons]  restarts daemons";;
	esac
}

# Wait in default polling manner on a condition
wait_on() {
	for i in $(seq "${2:-${WAIT_TRIES}}"); do
		eval "${1}" && return 0
		sleep "${3:-${WAIT_POLLRATE}}"
	done
	echo "ERROR: Gave up waiting on condition ${1}! You should debug this to avoid wasting time in init!"
	return 1
}

on_boot() {
	# mount the API filesystem
	# /proc, /sys, /run, /dev, /run/lock, /dev/pts, /dev/shm
	echo_color 3 mounting API filesystem...
	mountpoint -q /proc  || mount -t proc proc /proc -o nosuid,noexec,nodev
	mountpoint -q /sys   || mount -t sysfs sys /sys -o nosuid,noexec,nodev
	mountpoint -q /run   || mount -t tmpfs run /run -o mode=0755,nosuid,nodev
	mountpoint -q /dev   || mount -t devtmpfs dev /dev -o mode=0755,nosuid
	mkdir -p /dev/pts /dev/shm
	mountpoint -q /dev/pts || mount -t devpts devpts /dev/pts -o mode=0620,gid=5,nosuid,noexec
	mountpoint -q /dev/shm || mount -t tmpfs shm /dev/shm -o mode=1777,nosuid,nodev
	mount -o remount,rw /
	
	# TODO: Rotate X number of logs, or timestamp?
	echo_color 3 logging init to /var/log/rc/initlog
	set -x
	mkdir -p /var/log/rc
	touch "/var/log/rc/initlog"
	exec 1>"/var/log/rc/initlog"
	exec 2>&1

	# initialize system
	echo_color 3 setting up loopback device...
	ip link set up dev lo

	# Consider modprobing these in case udev fails?
	#modprobe xhci_hcd
	#modprobe usbhid

	echo_color 3 initializing udev...
	if [ "${UDEV}" = "auto" ]; then
		if command -v systemctl >/dev/null 2>&1; then
			UDEV="systemd"
		elif command -v udevd >/dev/null 2>&1; then
			UDEV="eudev"
		else
			UDEV="busybox"
		fi
	fi
	if [ "${UDEV}" = "systemd" ]; then
		systemd-udevd --daemon
		udevadm trigger --action=add --type=subsystems
		udevadm trigger --action=add --type=devices
	elif [ "${UDEV}" = "eudev" ]; then
		udevd --daemon
		udevadm trigger --action=add --type=subsystems
		udevadm trigger --action=add --type=devices
	else # use busybox mdev as fallback:
		# TODO: hotplug might not exist. It's not a normally enabled feature anymore, CONFIG_UEVENT_HELPER enables it
		mdev -s
		echo /sbin/mdev > /proc/sys/kernel/hotplug
	fi

	echo_color 3 setting hostname...
	echo "${HOSTNAME}" >| /proc/sys/kernel/hostname

	echo_color 3 setting fd link...	
	ln -s /proc/self/fd /dev/fd

	# start the default daemons
	echo_color 3 starting daemons...
	for dmn in ${ENABLED}; do
		if [ "${dmn:0:1}" = '@' ]; then
			daemon start "${dmn:1}" > "/var/log/rc/${dmn:1}" 2>&1 &
		else
			daemon start "${dmn}"
		fi
	done
	
	echo_color 3 mounting rest of filesystems...
	wait_on "mount -a"

	if [ -x /etc/rc.local ]; then
		echo_color 3 executing /etc/rc.local...
		/etc/rc.local
	fi
}

on_shutdown() {
	# stop the default daemons
	echo_color 3 stopping daemons...
	for dmn in ${ENABLED}; do
		if [ "${dmn:0:1}" = '@' ]; then
			daemon stop "${dmn:1}" &
		else
			daemon stop "${dmn}"
		fi
	done

	if [ -x /etc/rc.local_shutdown ]; then
		echo_color 3 executing /etc/rc.local_shutdown...
		/etc/rc.local_shutdown
	fi

	# shut down udev
	echo_color 3 shutting down udev...
	if [ "${UDEV}" = systemd ]; then
		killall systemd-udevd
	elif [ "${UDEV}" = eudev ]; then
		killall udevd
	fi

	# umount the API filesystem
	echo_color 3 unmounting API filesystem...
	umount -r /run
}

# daemon [start/stop/restart/poll/exists] service_name
daemon() {
	case "${1}" in
		start)
			echo_color 2 starting "$2"...
			;;
		stop)
			echo_color 1 stopping "$2"...
			;;
		restart)
			;;
		poll)
			;;
		exists)
			;;
	esac
	
	if command -v "${2}_${1}" >/dev/null 2>&1; then
		eval "${2}_${1}"
	else
		eval "default_${1} \"${2}\""
	fi
}

default_start() {
	"${1}"
}

default_stop() {
	killall "${1}"
}

default_restart() {
	daemon stop "${1}"
	daemon start "${1}"
}

default_poll() {
	pgrep "(^|/)${1}\$" >/dev/null 2>&1
}

default_exists() {
	command -v "${1}" >/dev/null 2>&1
}

echo_color() {
	color="$1"
	shift
	printf "\033[1;3%sm%s\033[00m\n" "${color}" "$*"
}

in_list() {
	for x in $2; do
		if [ "${x}" = "${1}" ]; then
			return 0
		fi
	done
	return 1
}

# Define all services in src/services/ and a SERVICES variable listing them
@services_include@

if [ -r /etc/busyrc.conf ]; then
	. /etc/busyrc.conf
fi

# Populate a reasonable default for DAEMONS
if [ -z "${DAEMONS}" ]; then
	DAEMONS="${ENABLED//@/}"
	for dmn in ${SERVICES}; do
		if daemon exists "${dmn}" && ! in_list ${dmn} "${DAEMONS}"; then
			DAEMONS="${DAEMONS} ${dmn}"
		fi
	done
fi

main $@
