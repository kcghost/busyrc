
pulseaudio_start() {
	pulseaudio --system --daemonize=true --disallow-exit=true --log-target=syslog
}
