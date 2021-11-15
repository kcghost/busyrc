
systemd_modules_load_start() {
	systemd-modules-load
}

systemd_modules_load_stop() {
	return 1
}

systemd_modules_load_poll() {
	return 1
}

systemd_modules_load_exists() {
	return 1
}

# Hyphens are not supported in function names, but are in aliases for some reason (ash)
alias systemd-modules-load_start="systemd_modules_load_start"
alias systemd-modules-load_stop="systemd_modules_load_stop"
alias systemd-modules-load_poll="systemd_modules_load_poll"
alias systemd-modules-load_exists="systemd_modules_load_exists"