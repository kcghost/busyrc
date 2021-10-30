
sshd_start() {
	eval "$(command -v sshd)"  # sshd requires an absolute path, so grab path from command -v
}

sshd_restart() {
	# Make sure busyrc doesn't hang up when restarting it remotely
	# TODO: Address "busybox" reference, might not be in PATH
	busybox setsid sh -c '"$0" stop "$@"; "$0" start "$@"' "$0" "$@"
}
