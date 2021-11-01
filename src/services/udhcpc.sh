
# For configuration of a reliable ethernet network interface or similiar, not for wifi
udhcpc_start() {
	if ip link | grep -Fq ${NETWORK_INTERFACE}; then :; else
		echo_color 3 "waiting for ${NETWORK_INTERFACE} to settle..."
		wait_on "ip link | grep -Fq ${NETWORK_INTERFACE}"
	fi
	udhcpc -i ${NETWORK_INTERFACE} -S -s /usr/local/libexec/busyrc-udhcpc.script
}

udhcpc_stop() {
	return 0
}

udhcpc_poll() {
	return 1
}

udhcpc_exists() {
	# Don't list sysinit actions
	return 1
}

