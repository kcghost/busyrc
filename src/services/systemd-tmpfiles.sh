
systemd_tmpfiles_start() {
	systemd-tmpfiles --create --remove --boot
}

systemd_tmpfiles_stop() {
	systemd-tmpfiles --clean
}

systemd_tmpfiles_poll() {
	return 1
}

systemd_tmpfiles_exists() {
	return 1
}

# Hyphens are not supported in function names, but are in aliases for some reason (ash)
alias systemd-tmpfiles_start="systemd_tmpfiles_start"
alias systemd-tmpfiles_stop="systemd_tmpfiles_stop"
alias systemd-tmpfiles_poll="systemd_tmpfiles_poll"
alias systemd-tmpfiles_exists="systemd_tmpfiles_exists"
