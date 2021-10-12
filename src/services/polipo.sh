
polipo_start() {
	su -c 'polipo daemonise=true logFile="/var/log/polipo.log"' -s /bin/sh - nobody
}
