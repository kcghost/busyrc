
alsa_start() {
	if wait_on "[ -c /dev/snd/controlC0 ]"; then
		alsactl restore || alsactl --no-lock restore
		return
	fi
	return 0
}

alsa_stop() {
	mkdir -p /var/lib/alsa
	alsactl store || alsactl --no-lock store
}

alsa_poll() {
	return 1
}

alsa_exists() {
	# Don't list sysinit actions
	return 1
}
