
bluetoothd_start() {
	wait_on dbus_poll
	bluetoothd
}