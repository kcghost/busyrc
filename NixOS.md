NixOS Known Issues and Workarounds
==================================

Look here first if you are running into trouble with your NixOS configuration.

startx
------

Currently the only 'display manager' supported is startx. (If you manage to get another display manager working, please file a pull request with the fix :)).
Please put the following in your configuration.nix:
```
services.xserver.displayManager.startx.enable = true;
```

You will also need a `~/.xinitrc` that tells X what programs to start, most likely a whole desktop environment.
Use the following example for KDE Plasma:
```
[ -f ~/.xprofile ] && . ~/.xprofile
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
  eval $(dbus-launch --exit-with-session --sh-syntax)
fi

export DESKTOP_SESSION=plasma
# If GLX is messed up (see systemd-tmpfiles):
#export QT_XCB_GL_INTEGRATION=none
exec startplasma-x11

# For debugging:
#exec xterm -fullscreen
```

GNOME and others are untested, but it should be something like:
```
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
exec gnome-session
```

User Permissions
----------------

This init does *not* start a logind, which would normally controls access to dev entries
for keyboard input and video that X11 needs. Users need to be in the "input" and "video" groups so X11 can start and act normally.
It also configures pulseaudio to be a system daemon, so additionally normal users need to be in the "audio" group.

This does represent a relatively minor security issue, you may wish to think twice if the system is shared by multiple or untrustworthy users.

Follow the following example for your configuration.nix:
```
  users.users.nixuser = {
    isNormalUser = true;
    extraGroups = [ "audio" "input" "video" ];
    hashedPassword = "<hashed_password>;
  };
```

nixos-rebuild
-------------

`sudo nixos-rebuild switch` is broken.
nix-os-rebuild calls the `switch-to-configuration` perl script, which is closely tied to systemd as it attempts to restart systemd units.
Specifically the switch will fail when the script attempts to communciate with systemd over dbus, it looks for "org.freedesktop.systemd1".
Thankfully the script quits out before any of that when called for "boot" instead.

Use the following workaround to switch to a new system without using "switch":
```
sudo nixos-rebuild boot
sudo /nix/var/nix/profiles/system/activate
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

init_shell
----------

Included with the minirc installation is a wrapper for the busybox ash shell, available as 'init_shell' in PATH.
You can test an init envrionment with:
```
env -i init_shell
PATH="$PATH:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin" # traditonal linux paths
PATH="$PATH:/usr/lib/systemd" # systemd libexec components normally hidden from PATH
PATH="$PATH:/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin" # NixOS standard path
PATH="$PATH:/run/current-system/sw/lib/systemd" # systemd libexec components in NixOS
```

Or leave out the PATH adjustments to work with only busybox builtins. (Press TAB twice to see all builtins).

systemd units
-------------

The minirc installation leaves systemd intact, and it's useful to search through systemd units in /etc/ for ExecStart attributes to learn how parts of the system are normally executed.
The following uses [ripgrep](https://github.com/BurntSushi/ripgrep) to search through /etc for a keyword:
```
rg -L /etc nix-daemon
```

init
----

Nix has two init 'stages' before actually starting systemd as PID 1.

You can see an 'init=' specified in /proc/cmdline, but that is a lie on most systems.
If an initrd is given to the kernel, the kernel will instead run the init inside that and ignore the `init=` on the cmdline.
That `init=` script is actually Stage 2 init, Stage 1 is inside the initrd andlooks at the cmdline and executes that stage when it is done.
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
minirc is best placed at the 'systemd' level, and NixOS provides an oddly named: `boot.systemdExecutable` option for overriding the PID 1 init, the contents of that option get executed at the end of Stage 2 init.
So despite the name, and the "starting systemd..." message from Stage 2, it can be any init system you want.

The [NixOS Init Freedom](https://sr.ht/~guido/nixos-init-freedom/) project does the same using s6 as the init system, as well as attempts to automagically convert systemd units to s6.
As much as reasonably possible, this project will avoid doing that. Part of the point is to have an easily traceable init without the complex cruft.

udev
----

NixOS being a systemd distro, it uses `systemd-udev`. `udev` used to be a separate entity from systemd, but it's entire codebase was merged with systemd sources and maintained from there.
Which is frankly insane. Thankfully the resulting executable, despite the name, can be called on its own and act separately from systemd. So keeping it as "the udev" is often the right choice for any distro that normally uses systemd.

Something to keep in mind, hardly any device support is builtin to the kernel itself, it needs to be modprobed, which will automatically happen as a result of udev. That includes things like a USB mouse and keyboard however, so if udev fails to start for whatever reason, the user at a nromal desktop is stuck looking at a getty session they can't type into.
Might want to consider some early modprobes for common input devices or kernel configuration advice for building in support, should theorhetically reduce boot time as well.

dbus
----

Starting dbus in a more "normal Linux" way of `dbus-daemon --system` seems fine for most purposes.
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

The default display manager lightdm doesn't work either, some other issue.

dhcpcd
------

dhcpcd tries to run /etc/dhcpcd.exit-hook, which calls systemctl and complains. But the daemon starts anyway and operates just fine.

One annoying aspect in NixOS is there is no `/etc/dhcpcd.conf`, instead Nix generates a config file in the nix store and the systemd unit references it directly.
NixOS has a bad habit of doing this for many services, it's a bit perplexing given there is a dedicated system to managing /etc.
There is a hack in minirc-init.nix to grab it and put it back in its standard place, but it could break with updates to NixOS.

acpid
-----

Like dhcpcd, the configuration is not in `/etc/acpi/events/` where it should be, and given it's a whole directory a link needs to be made.
Also, the binary isn't even in PATH, so it needs to be exposed.

nix-daemon
----------

This seems to be necessary for stuff like ephemeral shells and other Nix management features. Easy enough to start up and seems to behave well.

systemd-logind
--------------

I believe minirc *could* start this service separatley from systemd itself, if it turns out to be truly necessary for something.
A big issue that occurs without it is that X can't get any input from the mouse or keyboard.
This happens since /dev/input entries are only accessible by root or members of the 'input' group.
The same goes for some graphics entries for the 'video' group. X is started as the user, and the user is not normally a member of either of these groups.

As far as I understand systemd-logind runs as root, and X negotiates with it for for the file descriptors of these devices, allowing it access despite not being a member.
minirc could start this daemon, and I believe it mostly works, but without some further setup I don't care to debug the X log still complains about not being a valid session or something.

This was a huge pain to debug, and I don't understand why this service is necessary. It can be worked around by adding your user to the 'input' and 'video' groups.

systemd-tmpfiles and opengl drivers
-----------------------------------

Another odd issue with starting X is that all of KDE refused to start without the follwing hack in `.xinitrc`:
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
This is disabled in NixOS, see `/etc/pulse/client.conf`. This might be the best bet if you heed the nasty warnings and want a user daemon for pulseaudio. It's sneaky though, it is non-obvious how the daemon gets started without the user actually knowing about this fun-fact.

Or you can just configure NixOS for the system daemon, which sets up the `pulse` user and you can start pulseaudio like a normal system service.
This has several benefits anyway and seems to be the best choice for a trusted workstation, so that's what this project is going with.

And of course, nixpkgs doesn't use the configuration place (`/etc/pulse/system.pa'`) and it needs to be ripped from the systemd Exec line so it can be invoked normally.
To be fair I needed strace to find out it should be system.pa and not default.pa, pulseaudio does not make this obvious.

upowerd
-------

UPowerd is a little strange, as it has a similar-ish mechanism that pulseaudio autospawn has.
Calling the `upower` client automatically spawns the daemon, but it needs to run as superuser so...I don't understand why you would want a mechanism like that for this purpose.
NixOS normally calls `upowerd` directly in its systemd unit. That isn't something you can do easily in a 'traditional' Linux distro however, as upowerd is in a libexec directory hidden from PATH.
It's more portable to let the upower client start the daemon, it's just confusing how it operates and I really wish that it didn't do that.
