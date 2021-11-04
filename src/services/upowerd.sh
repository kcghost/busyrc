
upowerd_start() {
	wait_on dbus_poll
	# Let dbus start upowerd by invoking upower, not normally available in PATH
	upower
}

upowerd_exists() {
	default_exists upower
}
