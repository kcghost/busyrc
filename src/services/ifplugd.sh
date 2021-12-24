
# For configuration of a reliable ethernet network interface or similiar, not for wifi
ifplugd_start() {
	if ip link | grep -Fq ${NETWORK_INTERFACE}; then :; else
		echo_color 3 "waiting for ${NETWORK_INTERFACE} to settle..."
		wait_on "ip link | grep -Fq ${NETWORK_INTERFACE}"
	fi
	#udhcpc -i ${NETWORK_INTERFACE} -S -s /usr/local/libexec/busyrc-udhcpc.script
	# TODO: Figure out portable libexec
	# TODO: Support maybe a whole list of network interfaces that should be ifplug monitored?
	ifplugd -F -i ${NETWORK_INTERFACE} -r /usr/local/libexec/busyrc-ifplugd.action
}
