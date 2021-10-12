
dbus_start() {
	mkdir -p /run/dbus
	dbus-uuidgen --ensure
	dbus-daemon --system
}

dbus_stop() {
	killall dbus-launch
	killall dbus-daemon
	rm /run/dbus/pid
}

dbus_poll() {
	test -e /run/dbus/pid
}
