
# The defaults do fine for this daemon, but just naming it would cause
# confusion for overrides since the hyphen can't be used in function names :(
nixdaemon_start() {
	default_start "nix-daemon"
}

nixdaemon_stop() {
	default_stop "nix-daemon"
}

nixdaemon_poll() {
	default_poll "nix-daemon"
}

nixdaemon_exists() {
	default_exists "nix-daemon"
}
