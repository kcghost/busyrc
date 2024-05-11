
try_udhcpc() {
	echo_color 3 "waiting for interface ${1}..."
	# Keep trying for 100 seconds, wifi might be pretty slow to get started
	wait_on "netif_up ${1}" 1000
	echo_color 3 "interface ${1} is up, starting udhcpc for it"
	udhcpc -i ${1} -n -q -S -s /etc/busyrc/udhcpc.script
}

udhcpc_start() {
	for netif in ${NETWORK_INTERFACES}; do
		try_udhcpc "${netif}" &
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
