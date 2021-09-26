{ pkgs ? import <nixpkgs> {}, packageSrc ? ./. }:

# TODO: configure busybox for speed, builtin calls to avoid forking, make use of busybox in rc init

pkgs.stdenvNoCC.mkDerivation {
  name = "minirc";
  src = ./.;
  buildInputs = [pkgs.which];
  propagatedBuildInputs = [
    (pkgs.busybox.override { extraConfig = ''
        CONFIG_INSTALL_APPLET_DONT y
        CONFIG_INSTALL_APPLET_SYMLINKS n
    '';})
  ];
  installFlags = [ "prefix=/" "DESTDIR=$(out)" ];
}
