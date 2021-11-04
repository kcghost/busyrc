#!/bin/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC3057

# TODO: Support 'init environment' argument for testing

# NixOS rewrites the shebang line, so busybox could technically be anywhere
busybox_path=$(readlink -n /proc/$$/exe)
exec ${busybox_path} $@

