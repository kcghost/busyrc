#!/bin/sh
# This file is sourced by /sbin/rc and can be used to locally change
# configuration variables and startup functions.
#
# ======================================
# == Defining configuration variables ==
# ======================================

# This is a space-separated list of all daemons which are listed to the user
# The default lists all existing services known from built in sources (SERVICES) and ENABLED
# If you define services in busyrc.conf consider adding to SERVICES to make use
# of the default DAEMONS list, or just define a full DAEMONS list yourself
@daemons_include@

# This is a space-separated list of daemons which are run on boot. You may
# prefix a daemon name with a "@" character to make it run in the background.
ENABLED="@syslogd @klogd @alsa @dbus @upowerd @wpa_supplicant @ifplugd @sshd"

# Choose the udev implementation."auto" prefers systemd to eudev to busybox
#UDEV="auto"
#UDEV="systemd"
#UDEV="eudev"
#UDEV="busybox"

# List of interfaces which should be monitored by ifplugd (for automatic DHCP)
# Typically all wired and wireless interfaces
#NETWORK_INTERFACES="eth0 wlan0"
@networks_include@

# List of interfaces which should be passed to wpa_supplicant
#WIFI_INTERFACES="wlan0"
@wireless_include@

# How long to wait between waiting for a condition to be satisfied 
# (like a device to come up) and how many times to try
# WAIT_POLL must be a valid value for "sleep"
#WAIT_POLL="0.1"
#WAIT_TRIES="30"

# ==============================================================================
# == Overriding start/stop/restart/poll/exists scripts for individual daemons ==
# ==============================================================================

# Each daemon consists of the functions start, stop, restart, poll, and exists.
# They are defined in the style of <daemon_name>_<function>, e.g. dbus_start
# Any missing function falls back to the following defaults:
# <daemon_name>_start:   Execute <daemon_name>, must exist in PATH
# <daemon_name>_stop:    killall <daemon_name>
# <daemon_name>_restart: stop and start
# <daemon_name>_poll:    pgrep for <daemon_name>
# <daemon_name>_exists:  Check in PATH (command -v), determines list to user

# Not all functions need not be defined per daemon, and simple daemons that
# match their command name need not be defined at all.

# New daemons can be provided in this file, as well as existing ones overridden
# simply be redefining the function here.

# Example:
# sshd_start () {
#     /usr/bin/sshd -f /my/other/config.conf
# }
