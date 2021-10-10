minirc - minimalistic rc script
===============================

Note: This is a fork of minirc with several improvements, API changes, and
a focus on supporting NixOS in particular.
The original minirc can be found [here.](https://github.com/hut/minirc)

The script "rc" is a minimalistic init script made for use with busybox init.
It starts up udev, sets the hostname, mounts the file systems, starts the
daemons and so on.

Later, in the user space, you can use it to list currently running daemons and
individually start or stop them.

It was originally developed for Arch linux to get rid of systemd.
This fork primarily supports NixOS now, but it *should* still support Arch
and other distributions. At least it is meant to be as generic as possible.

![screenshot](screenshot.png)


Installing on NixOS
-------------------

WARNING: This whole project is experimental and you are practically
guaranteed to encounter some issues using it. NixOS has a convenient rollback
system that integrates into your bootloader, you might need to use it.

Quick start:
Clone this repository and put the following in your `configuration.nix`:

```
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <path-to>/minirc/minirc-init.nix
    ];
```

Only the startx display manager is supported right now, so you will also need:
```
services.xserver.displayManager.startx.enable = true;
```

You will also need to add audio, input, and video groups to your login users:
```
  users.users.nixuser = {
    isNormalUser = true;
    extraGroups = [ "audio" "input" "video" ];
    hashedPassword = "<hashed_password>;
  };
```

Then `sudo nixos-rebuild boot` and reboot.

Carefully read through the known issues and workarounds in
[this document](NixOS.md) before installing. It contains helpful details on how 
to use startx and why the above workarounds are necessary.

Installing on Arch or other distributions
-----------------------------------------

WARNING: Unknown if this project still works on Arch. You may want to take a
look at the [original project](https://github.com/hut/minirc) that has an AUR
package.

Dependencies: busybox, optionally eudev or systemd (for udev)

```
sudo make install
```

Then find a way to point init in your Linux distribution to busybox init, should
be /sbin/init. (Double check /sbin/init is a symlink to busybox).
From there busybox init will make use of /etc/inittab, which calls the rc script
for system initialization.

You will want to configure /etc/minirc.conf to your needs. It contains
informations on how to define new daemons or override existing ones.
See sections "Dealing with services" and "Further configuration".

Reboot.

Dealing with services
---------------------

Note: This API differs from the original minirc.

The variable DAEMONS contains a space-separated list of services that minirc
lists when you ask which services currently run.

The variable ENABLED contains a space-separated list of services that are
started on boot. Using an @ symbol in front of the daemon ensures it will run
as a background process rather than sequentially. This is preferred most of the
time so you can boot quickly, but it may require additional logic to wait for
another service or resource first.

You can override DAEMONS, ENABLED, and define or override services in
/etc/minirc.conf.  This file is simply sourced by the script right after 
defining the default variables.

To add or override another service you must define the appropriate actions of 
that service. See the comments in [minirc.conf](minirc.conf) for details.

Further configuration
---------------------

1. udev

   You need to decide what to use to set up the devices and load the modules.
   minirc supports busybox's mdev, systemd's udev, and a fork of udev, eudev,
   by default.  You can change the udev system by writing UDEV=busybox,
   UDEV=systemd, or UDEV=eudev respectively into /etc/minirc.conf.

   eudev and systemd's udev work out of the box, so they are recommended.  To
   set up mdev, you can use this as a reference:
   https://github.com/slashbeast/mdev-like-a-boss.

2. Local startup script

   Minirc will run /etc/minirc.local on boot if the file exists and has the
   executable bit set. This allows the user to run commands in addition to the
   basic startup that minirc provides. This is a good place to load modules if
   udev does not detect that they should be loaded on boot.


Usage of the user space program
-------------------------------

Run "rc --help" for information.  Never run "rc init" except during the boot
process, when called by busybox init.

About
-----

* Authors: Roman Zimbelmann, Sam Stuewe, Casey Fitzpatrick
* License: GPL2

Parts of the function on_boot() and the start/stop function of iptables were
taken from archlinux initscripts (http://www.archlinux.org).  I was unable to
determine the author or authors of those parts.

More information on the Arch Wiki: https://wiki.archlinux.org/index.php/Minirc
