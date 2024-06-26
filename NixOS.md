NixOS Known Issues and Workarounds
==================================

Look here first if you are running into trouble with your NixOS configuration.

**WARNING**: This project no longer specifically targets NixOS. This is because
NixOS in general eventually caused this author enough chagrin to give up on it.
It should still work, but it is even less well tested than it was before.


Installing on NixOS
--------------------------------------------------------------------------------

**WARNING**: This whole project is experimental and you are practically
guaranteed to encounter some issues using it. NixOS has a convenient rollback
system that integrates into your bootloader, you might need to use it.
Carefully read through this whole document before installing so you know abit of
what you are getting yoursefl into.

Quick start:
Clone this repository and put the following in your `configuration.nix`:

```
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <path-to>/busyrc/busyrc-init.nix
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

busyrc provides defaults for both /etc/inittab and /etc/busyrc/busyrc.conf.
The default configuration is not guaranteed to start every service NixOS would 
normally provide, it only checks for a few important ones.

Imporant init scripts can be defined and overidden in the following manner:
```
  environment.etc = {
    "busyrc/busyrc.conf".text = ''
      UDEV="systemd"
      ENABLED="@syslogd @klogd @dbus @acpid @systemd-tmpfiles @systemd-modules-load @nixdaemon @mycustomservice"
      NETWORK_INTERFACES="eno1"
    '';

    "inittab".text = ''
      ::sysinit:/run/current-system/sw/bin/rc init
    '';
    "rc.local" = {
        text = ''
          #!/bin/sh
          modprobe fuse
        '';
        mode = "0744";
    };
  };

```

startx
------

Currently the only 'display manager' supported is startx. (If you manage to get another display manager working, please file a pull request with the fix :)).
Please put the following in your configuration.nix:
```
services.xserver.displayManager.startx.enable = true;
```

You will also need a `~/.xinitrc` that tells X what programs to start, most likely a whole desktop environment or window manager.
This portion should be common to any .xinitrc you write:
```
[ -f ~/.xprofile ] && . ~/.xprofile
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
  eval $(dbus-launch --exit-with-session --sh-syntax)
fi

# For debugging:
#exec xterm -maximized
```

NixOS does not have much readily available information on starting the various desktop environments under startx.
Here are a few I have tested:

#### KDE Plasma

```
export DESKTOP_SESSION=plasma
# If GLX is messed up (see notes on systemd-tmpfiles):
#export QT_XCB_GL_INTEGRATION=none
exec startplasma-x11
```

#### LXQt

When LXQt is used without lightdm you should install `gnome.adwaita-icon-theme` otherwise application icons don't show for some reason.
This doesn't have to do with busyrc or even startx, the same happens when using sddm and systemd.

```
export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:/run/current-system/sw/share
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/run/current-system/sw/share
exec startlxqt
```

#### XFCE

```
exec startxfce4
```

#### MATE

```
exec mate-session
```

#### GNOME

Honestly no idea. Please file a pull request or issue if you know some way to start it. `gnome-session` isn't even available in PATH.
Seems to have fairly tight integration with systemd and gdm.

User Permissions
----------------

This init does *not* start a logind, which would normally controls access to dev entries
for keyboard input and video that X11 needs. Users need to be in the "input" and "video" groups so X11 can start and act normally.
It also configures pulseaudio to be a system daemon, so additionally normal users need to be in the "audio" group.

This does represent a relatively minor security issue, you may wish to think twice if the system is shared by multiple or untrustworthy users.

Follow this example for your configuration.nix:
```
  users.users.nixuser = {
    isNormalUser = true;
    extraGroups = [ "audio" "input" "video" ];
    hashedPassword = "<hashed_password>;
  };
```

autologin and startx
--------------------

You might have something like this in your configuration.nix already:
```
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "<your_user>";
```

That won't work anymore since startx is not really a display manager.
Instead there is just a normal getty terminal on tty7, and you can login to whichever tty you like and execute 'startx'.

There *is* a NixOS option for getty autologin which this project takes into account when building inittab however:
```
services.getty.autologinUser = '<your_user>';
```
That will ensure you are logged into each terminal automatically. (Take a look at the /etc/inittab spec in busyrc-init.nix and just override it if you need more fine-grained control.)

Next, you probably want an X session to start automatically. You can do this in the [standard hook into profile manner](https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login).
Try putting the following in `~/.profile` (or `~/.bash_profile` or `~/.bash_login` if you have them, since those files take precedence in a bash login shell):
```
if [ -z "${DISPLAY}" ] && [ "$(tty)" = "/dev/tty7" ]; then
  startx
fi
```

Note that often `exec startx` is used above, but this could be dangerous as a broken .xinitrc will cause the X server to repeatedly attempt to start, and take away terminal control from the user as a result.
If startx breaks, it's best to exit out to a normal terminal you can use for debugging.

nixos-rebuild
-------------

`sudo nixos-rebuild switch` is broken.
nix-os-rebuild calls the `switch-to-configuration` perl script, which is closely tied to systemd as it attempts to restart systemd units.
Specifically the switch will fail when the script attempts to communciate with systemd over dbus, it looks for "org.freedesktop.systemd1".
Thankfully the script quits out before any of that when called for "boot" instead.

`pulseaudio` also needs a restart for some reason.

A workaround command `nixos-switch` is installed that just does the following:
```
nixos-rebuild boot
/nix/var/nix/profiles/system/activate
rc restart pulseaudio
```

ntfs mounts
-----------

If you follow the [recommended instructions for mounting an NTFS filesystem with read-write capability](https://nixos.wiki/wiki/NTFS) you'll find that it no longer works under busyrc, it just mounts read-only.
The reason for this is that NixOS generates a slightly non-standard /etc/fstab with "ntfs" as the fs-type rather than the FUSE module "ntfs-3g". Technically this means that it should use the builtin kernel NTFS support, and typically the kernel doesn't have write support enabled. The normal `mount` command in NixOS knows to use the FUSE module anyway (maybe it knows the kernel doesn't have the write support?), busybox mount does not.

To workaround this, just remove NTFS entries from `hardware-configuration.nix` and use the following pattern for defining your NTFS mount pounts:
```
  fileSystems."/path/to/mount/to" =
    { device = "/path/to/the/device";
      fsType = "ntfs-3g"; 
      options = [ "rw" "uid=theUidOfYourUser"];
    };
```

NixOS Notes
===========

NixOS has a unique boot procedure and is closely tied to systemd.
As such, this project encounters a lot of pain points, and I have written some notes on each pain point here and how I have resolved them.
They might help you if any of them breaks in time (quite likely), or if there is a new pain point I have not seen or addressed. (Please file an issue or make a pull request if you fix it).

Bonus: Some documentation on debugging strategies, and doing funny things with NixOS boot.

philosophy
----------

This project aims to provide an easily traceable, readable, and debuggable init system.
Users should not be uncertain of how exactly daemons get started, or which daemons get started.
Most solutions do take the path of least resistance, but wherever reasonably possible it's best to avoid systemd and "modern linux" methods.
Instead this project aims to make NixOS act a little more like a standard Linux distro, especially so that the 'rc' script is at least theorhetically compatible across
differing distributions.

bbwrap
------

Included with the busyrc installation is a wrapper for custom configured busybox, available as 'bbwrap' in PATH.
You can test an init envrionment with:
```
env -i bbwrap ash
PATH="$PATH:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin" # traditonal linux paths
PATH="$PATH:/usr/lib/systemd" # systemd libexec components normally hidden from PATH
PATH="$PATH:/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin" # NixOS standard path
PATH="$PATH:/run/current-system/sw/lib/systemd" # systemd libexec components in NixOS
```

Or leave out the PATH adjustments to work with only busybox builtins. (Press TAB twice to see all builtins).
This is useful since at least theorhetically it's faster and portable to use builtins since they don't fork, and busybox can build in practically all of it's capabilities.

systemd units
-------------

The busyrc installation leaves systemd intact, and it's useful to search through systemd units in /etc/ for ExecStart attributes to learn how parts of the system are normally executed.
The following uses [ripgrep](https://github.com/BurntSushi/ripgrep) to search through /etc for a keyword:
```
rg -L /etc nix-daemon
```

init
----

Nix has two init 'stages' before actually starting systemd as PID 1.

You can see an 'init=' specified in /proc/cmdline, but that is a lie (on most systems).
If an initrd is given to the kernel, the kernel will instead run the init inside that and ignore the `init=` on the cmdline.
That `init=` script is actually Stage 2 init, Stage 1 is inside the initrd and looks at the cmdline and executes that stage when it is done.
Stage 2 is written in such a way that it can handle being the only init script, Stage 1 can be skipped entirely if need be.

By default, NixOS runs with an initrd. In fact it is difficult to disable the initrd.
`boot.initrd.enable = false` does not have the intended effect, it's mostly only there for container usage.
GRUB and other bootloaders assume the presense of an initrd, and don't take the option into account.
But there *is* a nasty hack, if you make initrd a 0 byte file the kernel will treat it as if it was not supplied.
The following snippet is a hacky way to boot straight into a root filesystem, and therefore only use Stage 2 init.
Note that you need kernel support to actually mount the rootfs built into the kernel (hence the extra config options), as the initrd would normally provide kernel modules for that.

```
  # Use GRUB boot loader
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
       efiSupport = true;
       device = "nodev";
    };
  };

  # Hacky way to make initrd 0 byes, therefore boot directly to rootfs
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [ "-o" "/dev/null" ];
  boot.kernelParams = [  "console=tty1" "root=PARTUUID=a1224c7b-adf8-414f-9c90-504b9a731cb6" ];
  boot.kernelPatches = [ {
    name = "simpleinit-config";
    extraConfig = ''
            EXT4_FS y
            BLK_DEV_SD y
            ATA y
            SATA_AHCI y
          '';
    } ];

```

While it's certainly possible to skip the Stage 2 init script, it probably isn't a great idea.
It's responsible for setting up NixOS's quirky pseudo read-only root filesystem.
busyrc is best placed at the 'systemd' level, and NixOS provides an oddly named: `boot.systemdExecutable` option for overriding the PID 1 init, the contents of that option get executed at the end of Stage 2 init.
So despite the name, and the "starting systemd..." message from Stage 2, it can be any init system you want.

The [NixOS Init Freedom](https://sr.ht/~guido/nixos-init-freedom/) project does the same using s6 as the init system, as well as attempts to automagically convert systemd units to s6.
As much as reasonably possible, this project will avoid doing that. Part of the point is to have an easily traceable init without the complex cruft.

udev
----

NixOS being a systemd distro, it uses `systemd-udev`. `udev` used to be a separate entity from systemd, but it's entire codebase was merged with systemd sources and maintained from there.
Which is frankly insane. Thankfully the resulting executable, despite the name, can be called on its own and act separately from systemd. So keeping it as "the udev" is often the right choice for any distro that normally uses systemd.

Something to keep in mind, hardly any device support is builtin to the kernel itself, it needs to be modprobed, which will automatically happen as a result of udev. That includes things like a USB mouse and keyboard however, so if udev fails to start for whatever reason, the user at a normal desktop is stuck looking at a getty session they can't type into.
Might want to consider some early modprobes for common input devices or kernel configuration advice for building in support, should theorhetically reduce boot time as well.

dbus
----

Starting dbus in a more "normal linux" way of `dbus-daemon --system` seems fine for most purposes.
Not certain yet if the derivation from the systemd ExecStart of `dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only`
will cause any problems.

sddm
----

The sddm display manager normally used in conjunction with KDE is broken.
`systemd-cat` is used to start the X server, so that it logs to the systemd journal.
`systemd-cat` does not like running without systemd, though it might be possible to hack around it by providing a `/run/systemd/journal/stdout` unix socket.
Workaround for now is just use startx instead.

lightdm
-------

The default display manager lightdm doesn't work either, some other issue is happening.

dhcpcd
------

dhcpcd tries to run /etc/dhcpcd.exit-hook, which calls systemctl and complains. But the daemon starts anyway and operates just fine.

One annoying aspect in NixOS is there is no `/etc/dhcpcd.conf`, instead Nix generates a config file in the nix store and the systemd unit references it directly.
NixOS has a bad habit of doing this for many services, it's a bit perplexing given there is a dedicated system to managing /etc.
There is a hack in busyrc-init.nix to grab it and put it back in its standard place, but it could break with updates to NixOS.

acpid
-----

Like dhcpcd, the configuration is not in `/etc/acpi/events/` where it should be, and given it's a whole directory a link needs to be made.
Also, the binary isn't even in PATH, so it needs to be exposed.

nix-daemon
----------

This seems to be necessary for stuff like ephemeral shells and other Nix management features. Easy enough to start up and seems to behave well.

systemd-logind
--------------

I believe busyrc *could* start this service separatley from systemd itself, if it turns out to be truly necessary for something.
A big issue that occurs without it is that X can't get any input from the mouse or keyboard.
This happens since /dev/input entries are only accessible by root or members of the 'input' group.
The same goes for some graphics entries for the 'video' group. X is started as the user, and the user is not normally a member of either of these groups.

As far as I understand systemd-logind runs as root, and X negotiates with it for for the file descriptors of these devices, allowing it access despite not being a member.
busyrc could start this daemon, and I believe it mostly works, but without some further setup I don't care to debug the X log still complains about not being a valid session or something.

This was a huge pain to debug, and I don't understand why this service is necessary. It can be worked around by adding your user to the 'input' and 'video' groups.

systemd-tmpfiles and opengl drivers
-----------------------------------

Another odd issue with starting X is that KDE initially refused to start without the following hack in `.xinitrc`:
```
export QT_XCB_GL_INTEGRATION=none
exec startplasma-x11
```

This is because X can't find the opengl drivers. The hack just forces that capability off, so it isn't ideal. They are meant to be located or symlinked at `/run/opengl-driver`, a location that oddly seems hardcoded into libglx.so.
This link is set up by systemd-tmpfiles, it can be seen in /etc/tmpfiles.d.
There might be other important things set up in this tmpfile format as well, NixOS provides `systemd.tmpfiles.rules` that anything might use, so it's easiest to play nice with systemd here.
Thankfully `systemd-tmpfiles` can be executed independently of systemd itself.

BTW, starting a terminal in .xinitrc and launching 'startplasma-x11' (or another desktop environment) from there is best for debugging purposes.

pulseaudio
----------

There are 3 different ways you can start pulseaudio, and every one of them is kind of a pain.
The modern normal way is a systemd user unit. It seems about equivalent to running `pulseaudio --start` in a user terminal.
I initially tried looping through users and starting `pulseaudio --start` for each user, but I believe only one instance is allowed at any time. (How does multiseat work?).

The older normal way is autospawn, which starts the user daemon if it doesn't exist already when any application that links with pulseaudio libraries calls into them.
This is disabled in NixOS, see `/etc/pulse/client.conf`. This might be the best bet if you heed the nasty warnings and want a user daemon for pulseaudio. It's sneaky though, it is non-obvious how the daemon gets started without the user actually knowing about this little fun-fact.

Or you can just configure NixOS for the system daemon, which sets up the `pulse` user and you can start pulseaudio like a normal system service.
This has several benefits anyway and seems to be the best choice for a trusted workstation, so that's what this project is going with.

And of course, nixpkgs doesn't use the right configuration place (`/etc/pulse/system.pa'`) and it needs to be ripped from the systemd Exec line so it can be invoked normally.
To be fair I needed strace to find out it should be system.pa and not default.pa, pulseaudio documentation does not make this obvious.

upowerd
-------

UPowerd is a little strange, as it has a similar-ish mechanism that pulseaudio autospawn has.
Calling the `upower` client automatically spawns the daemon, but it needs to run as superuser so...I don't understand why you would want a mechanism like that for this purpose.
NixOS normally calls `upowerd` directly in its systemd unit. That isn't something you can do easily in a 'traditional' Linux distro however, as upowerd is in a libexec directory hidden from PATH.
It's more portable to let the upower client start the daemon, it's just confusing how it operates and I really wish that it didn't do that.
