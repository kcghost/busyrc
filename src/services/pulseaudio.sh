
pulseaudio_start() {
	pulseaudio --system --daemonize=true --log-target=syslog
}
