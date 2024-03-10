
try_udhcpc() {
	echo_color 3 "waiting for interface ${1}..."
	# TODO: Might want to wait for specific operstate "up" or "unknown" rather than just existing
	wait_on "netif_exists ${1}"
	echo_color 3 "interface ${1} is available, starting udhcpc for it"
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
