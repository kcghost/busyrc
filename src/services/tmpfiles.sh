
# Hyphens are not supported in function names, so can't use 'systemd-tmpfiles'
tmpfiles_start() {
	systemd-tmpfiles --create --remove --boot
}

tmpfiles_stop() {
	systemd-tmpfiles --clean
}

tmpfiles_poll() {
	return 1
}

tmpfiles_exists() {
	return 1
}
