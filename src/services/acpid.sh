
acpid_start() {
	wait_on "[ -c /dev/input/event0 ]"
	acpid
}
