
iptables_start() {
	if [ -f /etc/iptables/iptables.rules ]; then
		iptables-restore < /etc/iptables/iptables.rules
	fi
}

iptables_stop() {
	for table in $(cat /proc/net/ip_tables_names); do
		iptables-restore < /var/lib/iptables/empty-"$table".rules
	done
}

iptables_poll() {
	sudo iptables -L -n | grep -m 1 -q '^ACCEPT\|^REJECT' >/dev/null 2>&1
}

iptables_exists() {
	[ -f /etc/iptables/iptables.rules ]
}
