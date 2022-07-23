busyrc - minimalistic rc script
===============================

**Note**: This is a fork of minirc with several improvements and API changes.
The original minirc can be found [here.](https://github.com/hut/minirc)

The script "rc" is a minimalistic init script made for use with busybox init.
It starts up udev, sets the hostname, mounts the file systems, starts the daemons and so on.

Later, in the user space, you can use it to list currently running daemons and individually start or stop them.

It was originally developed for Arch linux to get rid of systemd.
This fork primarily supports Ubuntu Focal now, but it *should* still support Arch and other distributions.
At least it is meant to be as generic as possible.
It previously targeted NixOS, and *should* still work, but it is untested.
Read [this document](NixOS.md) for NixOS install instructions and notes.

![screenshot](screenshot.png)

**WARNING**: This project is experimental and you are practically guaranteed to encounter some issues using it.
You should have a Live USB on hand to make changes to the disk and undo installation if necessary if the system is unbootable.
I also recommend setting up SSH access in case just your terminal gets hosed.

**WARNING**: It is unknown if this project still works on Arch.
You may want to look at the [original project](https://github.com/hut/minirc) that has an AUR package.

Installing on Ubuntu or most normal Linux distributions
--------------------------------------------------------------------------------

Dependencies: busybox, optionally eudev or systemd (for udev)
```
sudo apt install busybox busybox-syslogd

sudo make install-conf
sudo make install
```

Note that the true init on most Linux distributions is actually in initrd.
Usually a script in initrd will execute some traditional init, *probably* `/sbin/init`. 
`make install` assumes that is the case, but you may need to find out which for your distribution.

By default `make install-conf` attempts to autodetermine NETWORK_INTERFACES and WIRELESS_INTERFACES based on active interfaces.
It sets them up for basic ifplugd DHCP support and wpa_supplicant support.

You will want to configure `/etc/busyrc/busyrc.conf` to your needs.
It contains information on how to define new daemons or override existing ones.
See sections [Dealing with services](#dealing-with-services) and [Further configuration](#further-configuration).

You will likely want to configure user some [user services](#user-services) as well.
It is recommended to use `startx` to start X from a user profile rather than use a display manager, as well as start pulseaudio as a normal user.

Reboot.
When moving from systemd to busyrc, `sudo reboot` will not work.
Try `sudo kill -s SIGINT 1` instead.

Uninstalling
------------

If you need to go back to systemd, just use `make uninstall` to restore.
In a pinch you should be able to do `ln -sf /lib/systemd/systemd /sbin/init`.
And/or reinstall the systemd init package: `apt install --reinstall systemd-sysv`.

Dealing with services
---------------------

The variable DAEMONS contains a space-separated list of services that busyrc lists when you ask which services are currently running.

The variable ENABLED contains a space-separated list of services that are started on boot.
Using an @ symbol in front of the daemon ensures it will run as a background process rather than sequentially.
This is preferred most of the time so you can boot quickly, but it may require additional logic to wait for another service or resource first.

You can override DAEMONS, ENABLED, and define or override services in /etc/busyrc/busyrc.conf.
This file is simply sourced by the script right after defining the default variables.

To add or override another service you may need to define the appropriate actions of that service.
See the comments in [src/busyrc.conf.sh](busyrc.conf) for details.

Debugging
---------

The main rc script logs to `/var/log/rc/initlog`, and each backgrounded service prints to `/var/log/rc/service_name`.
The default configuration also starts up `syslogd` and `klogd`, with many services configured to use it.
Therefore many messages should show up in `/var/log/messages`.

Further configuration
---------------------

### udev

You need to decide what to use to set up the devices and load the modules.
busyrc supports busybox's mdev, systemd's udev, and a fork of udev, eudev, by default.
You can change the udev system by writing UDEV=busybox, UDEV=systemd, or UDEV=eudev respectively into /etc/busyrc.conf.

eudev and systemd's udev work out of the box, so they are recommended.
To set up mdev, you can use [this as a reference](https://github.com/slashbeast/mdev-like-a-boss).

### Local startup script

Busyrc will run `/etc/rc.local` on boot if the file exists and has the executable bit set.
This allows the user to run arbitrary commands in addition to the basic startup that busyrc provides.

In particular this is a good place to load modules not automatically integrated by udev, such as these for VirtualBox:
```
modprobe vboxdrv
modprobe vboxnetflt
```

It will similiarly run `/etc/rc.local_shutdown` on shutdown.


Usage of the user space program
-------------------------------

Run "rc --help" for information.  Never run "rc init" except during the boot process, when called by busybox init.

User services
-------------

The default inittab configuration starts console login shells on TTYs 1-7.
It is recommended to change the TTY7 line to automatically login your primary user:
```
tty7::respawn:agetty -a your_username tty7 linux
```

Instead of starting a display manager, it is recommended to start X11 directly as a user, as well as pulseaudio.
To do this, you should add your primary user to the `video`, `input`, and `audio` groups.
For printer support, you should also add your user to the `lp` group.

```
usermod -a -G video your_username
usermod -a -G input your_username
usermod -a -G audio your_username
usermod -a -G lp    your_username
```

Then to actually start services on autologin, add a block like this to `~/.profile` or other login shell initialization file:
```
if [ -z "${DISPLAY}" ] && [ "$(tty)" = "/dev/tty7" ]; then
  pulseaudio -D
  startx
fi
```

Note that [other guides online](https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login) often include `exec startx`.
I recommend against that, as a failing X configuration will cause X to continually attempt to start and potentially lock the user out of practical access to the terminal.
It is better to fail out to a console.

You will also need a `~/.xinitrc`, here is a typical one that starts cinnamon, with some examples for other desktop managers:
```
[ -f ~/.xprofile ] && . ~/.xprofile
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ] && type dbus-launch >/dev/null; then
  eval $(dbus-launch --sh-syntax --exit-with-session)
fi

# For debugging:
#exec xterm -maximized

#exec startxfce4
#exec openbox-session
#exec mate-session
#exec startlxqt

#export DESKTOP_SESSION=plasma
#exec startplasma-x11

#export XDG_SESSION_TYPE=x11
#export GDK_BACKEND=x11
#exec gnome-session

exec cinnamon-session
```

**Note**: I have not tested many desktop managers for Ubuntu Focal, only Cinnamon from [Cinnamon remix](https://ubuntucinnamon.org/).
I presume most work, though I do recall I couldn't find a way to start GNOME in NixOS.
I hope that is not the case in Ubuntu.

About
-----

* Authors: Roman Zimbelmann, Sam Stuewe, Casey Fitzpatrick
* License: GPL2

Parts of the function on_boot() and the start/stop function of iptables were
taken from archlinux initscripts (http://www.archlinux.org).  I was unable to
determine the author or authors of those parts.
