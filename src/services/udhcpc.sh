
udhcpc_start() {
	for NETWORK_INTERFACE in ${NETWORK_INTERFACES}; do	
		if ip link | grep -Fq ${NETWORK_INTERFACE}; then :; else
			echo_color 3 "waiting for ${NETWORK_INTERFACE} to settle..."
			wait_on "ip link | grep -Fq ${NETWORK_INTERFACE}"
		fi
		udhcpc -i ${NETWORK_INTERFACE} -n -q -S -s /etc/busyrc/udhcpc.script
	done
}

udhcpc_stop() {
	return 1
}

udhcpc_poll() {
	return 1
}

udhcpc_exists() {
	# Don't list sysinit actions
	return 1
}
