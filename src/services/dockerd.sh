
dockerd_start() {
	mount -t cgroup2 none /sys/fs/cgroup
	dockerd --log-driver=syslog &
}

