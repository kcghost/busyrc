
try_ifplugd() {
	echo_color 3 "waiting for interface ${1}..."
	wait_on "netif_exists ${1}"
	echo_color 3 "interface ${1} is available, starting ifplugd for it"
	ifplugd -I -F -i ${1} -r /etc/busyrc/ifplugd.action
}

ifplugd_start() {
	for netif in ${NETWORK_INTERFACES}; do
		try_ifplugd "${netif}" &
	done
}
