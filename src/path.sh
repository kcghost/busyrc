# NixOS rewrites the shebang line, so busybox could technically be anywhere
busybox_path=$(readlink -n /proc/$$/exe)

PATH="$PATH:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin" # traditonal linux paths
PATH="$PATH:/usr/lib/systemd" # systemd libexec components normally hidden from PATH
PATH="$PATH:/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin" # NixOS standard path
PATH="$PATH:/run/current-system/sw/lib/systemd" # systemd libexec components in NixOS

# Some busybox installations might not have SH_STANDALONE or PREFER_APPLETS features
# Also some applets supported by busybox might not be in PATH if symlinks were not created
# Or other "full" versions of the same utilties (with annoyingly different behavior) might be in PATH
# For consistency, prefer the full set of busybox applets whereever possible
# Find applets supported by busybox and define aliases for them so they can be called normally
if command -v "busybox" >/dev/null 2>&1; then
	for cmd in $(busybox --list); do
		# Note: Removing PATH and just testing for an exit value rather than
		# comparing string output (command -v = cmd) is a major speed improvement
		if ! PATH="" command -v "${cmd}" >/dev/null 2>&1; then
			# cmd is supported by busybox but no builtin is available
			# Define an alias so it can be used without prepending 'busybox'
			# Note: bash would need expand_aliases to use aliases in non-interactive mode, ash does not
			# Note: some cmds use chars (-,.) that alias can use but functions cannot (in ash shell, not POSIX)
			eval "alias ${cmd}=\"${busybox_path} ${cmd}\""
		fi
	done
fi
