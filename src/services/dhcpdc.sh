
dhcpdc_start() {
	if ip link | grep -Fq ${NETWORK_INTERFACE}; then :; else
		echo_color 3 "waiting for ${NETWORK_INTERFACE} to settle..."
		wait_on "ip link | grep -Fq ${NETWORK_INTERFACE}"
	fi
	dhcpcd -nqb
}
