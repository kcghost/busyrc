{config, pkgs, ...}:

let
  minirc-pkg = (pkgs.callPackage ./. {});
  pulseaudiod = if config.hardware.pulseaudio.enable then "@pulseaudio" else "";
in {
  # Only startx is supported by minirc at this time
  services.xserver.displayManager.startx.enable = true;

  # Enable system wide pulseaudio daemon
  hardware.pulseaudio.systemWide = true;

  environment.etc = {
    "minirc.conf".text = ''
      UDEV="systemd"
      ENABLED="@dbus @acpid @tmpfiles @nixdaemon @dhcpcd @alsa @upowerd ${pulseaudiod}"
      NETWORK_INTERFACE="eno1"
    '';
    inittab.text = ''
      # Start "rc init" on boot
      ::sysinit:/run/current-system/sw/bin/rc init

      # Setup login shells
      # You could use "-/bin/sh" for a direct login shell
      # or "agetty -a root tty1 linux" for autologin
      # A graphical display manager is traditionally launched on tty7
      tty1::respawn:/run/current-system/sw/bin/agetty tty1 linux
      tty2::respawn:/run/current-system/sw/bin/agetty tty2 linux
      tty3::respawn:/run/current-system/sw/bin/agetty tty3 linux
      tty4::respawn:/run/current-system/sw/bin/agetty tty4 linux
      tty5::respawn:/run/current-system/sw/bin/agetty tty5 linux
      tty6::respawn:/run/current-system/sw/bin/agetty tty6 linux
      tty7::respawn:/run/current-system/sw/bin/agetty tty7 linux


      # Shutdown when pressing CTRL+ALT+DEL (disabled by default)
      #::ctrlaltdel:kill -USR2 1

      # Stop all services on shutdown
      ::shutdown:/run/current-system/sw/bin/rc shutdown

      # Killing everything on shutdown
      ::shutdown:echo :: sending SIGTERM to all
      ::shutdown:/run/current-system/sw/bin/kill -s TERM -1
      ::shutdown:sleep 1
      ::shutdown:echo :: sending SIGKILL to all
      ::shutdown:/run/current-system/sw/bin/kill -s KILL -1

      # Unmount everything on shutdown
      ::shutdown:echo :: unmounting everything
      ::shutdown:/run/current-system/sw/bin/umount -a -r
      ::shutdown:/run/current-system/sw/bin/mount -o remount,ro /
    '';
    # Can't get 'let' variables directly afaik, so grab dhcpcdConf from dhcpcd.nix by grabbing it from systemd
    # This assumes an ExecStart with a --config argument, this might break in time
    "dhcpcd.conf".source = "${builtins.elemAt (builtins.match ".*--config ([^ ]+).*" config.systemd.services.dhcpcd.serviceConfig.ExecStart) 0}";
    # Grab pulse config and put it in the right place as well
    "pulse/system.pa".source = "${builtins.elemAt (builtins.match ".*--file=([^ ]+).*" config.systemd.services.pulseaudio.serviceConfig.ExecStart) 0}";
  };

  # Expose acpid which isn't normally in PATH, link config dir in default spot
  security.wrappers.acpid.source = "${pkgs.acpid}/bin/acpid";
  # Some odd quoting needs to be worked around here, might break in time
  system.activationScripts.acpidlink.text = ''
    mkdir -p /etc/acpi/
    rm -f /etc/acpi/events
    ln -sf "${builtins.elemAt (builtins.match ".*--confdir\' \'([^ ]+)\'.*" config.systemd.services.acpid.serviceConfig.ExecStart) 0}" "/etc/acpi/events"
  '';

  environment.systemPackages = [ minirc-pkg ];
  boot.systemdExecutable = "${minirc-pkg}/bin/init";
}
