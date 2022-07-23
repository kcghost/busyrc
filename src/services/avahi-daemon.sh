
avahi_daemon_start() {
	wait_on dbus_poll
	avahi-daemon
}

# Hyphens are not supported in function names, but are in aliases for some reason (ash)
alias avahi-daemon_start="avahi_daemon_start"
