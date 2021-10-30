
iptables_start() {
	if [ -f /etc/iptables/iptables.rules ]; then
		iptables-restore < /etc/iptables/iptables.rules
	fi
}

iptables_stop() {
	for table in $(cat /proc/net/ip_tables_names); do
		empty_file="/usr/share/iptables/empty-"$table".rules"
		# Support older iptables intallations
		if [ ! -f "${empty_file}" ]; then
			empty_file="/var/lib/iptables/empty-"$table".rules"
		fi
		iptables-restore < "${empty_file}"
	done
}

iptables_poll() {
	return 1
}

iptables_exists() {
	# Don't list sysinit actions
	return 1
}
