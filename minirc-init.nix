{pkgs, ...}:

let
  minirc-pkg = (pkgs.callPackage ./. {});
in {
  environment.systemPackages = [ minirc-pkg ];
  environment.etc = {
    "minirc.conf".source = ./minirc.conf;
    inittab.text = ''
      # Start "rc init" on boot
      ::sysinit:${minirc-pkg}/bin/rc init

      # Setup login shells
      # You could use "-/bin/sh" for a direct login shell
      # or "agetty -a root tty1 linux" for autologin
      # A graphical display manager is traditionally launched on tty7
      #tty1::respawn:${pkgs.util-linux}/bin/agetty tty1 linux
      tty2::respawn:${pkgs.util-linux}/bin/agetty tty2 linux
      tty3::respawn:${pkgs.util-linux}/bin/agetty tty3 linux
      tty4::respawn:${pkgs.util-linux}/bin/agetty tty4 linux
      tty5::respawn:${pkgs.util-linux}/bin/agetty tty5 linux
      tty6::respawn:${pkgs.util-linux}/bin/agetty tty6 linux
      #tty7::respawn:${pkgs.sddm}/bin/sddm

      # Shutdown when pressing CTRL+ALT+DEL (disabled by default)
      #::ctrlaltdel:kill -USR2 1

      # Stop all services on shutdown
      ::shutdown:${minirc-pkg}/bin/rc shutdown

      # Killing everything on shutdown
      ::shutdown:echo :: sending SIGTERM to all
      ::shutdown:${pkgs.util-linux}/bin/kill -s TERM -1
      ::shutdown:sleep 1
      ::shutdown:echo :: sending SIGKILL to all
      ::shutdown:${pkgs.util-linux}/bin/kill -s KILL -1

      # Unmount everything on shutdown
      ::shutdown:echo :: unmounting everything
      ::shutdown:${pkgs.util-linux}/bin/umount -a -r
      ::shutdown:${pkgs.util-linux}/bin/mount -o remount,ro /
    '';
  };
  boot.systemdExecutable = "${minirc-pkg}/bin/init";
}

