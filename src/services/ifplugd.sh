
ifplugd_start() {
	for NETWORK_INTERFACE in ${NETWORK_INTERFACES}; do	
		if ip link | grep -Fq ${NETWORK_INTERFACE}; then :; else
			echo_color 3 "waiting for ${NETWORK_INTERFACE} to settle..."
			wait_on "ip link | grep -Fq ${NETWORK_INTERFACE}"
		fi
		ifplugd -I -F -i ${NETWORK_INTERFACE} -r /etc/busyrc/ifplugd.action
	done
}
