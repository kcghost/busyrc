{ pkgs ? import <nixpkgs> {}, packageSrc ? ./. }:

pkgs.stdenvNoCC.mkDerivation {
  name = "busyrc";
  src = ./.;
  buildInputs = [pkgs.which];
  propagatedBuildInputs = [
    (pkgs.busybox.override { extraConfig = ''
        CONFIG_INSTALL_APPLET_DONT y
        CONFIG_INSTALL_APPLET_SYMLINKS n
        CONFIG_SH_IS_ASH y
        CONFIG_FEATURE_SH_STANDALONE y
        CONFIG_FEATURE_PREFER_APPLETS y
        CONFIG_FEATURE_SH_NOFORK y
    '';})
  ];
  installFlags = [ "prefix=/" "DESTDIR=$(out)" ];
  postInstall = ''
    mkdir -p "$out/bin"
    echo "#!$(which busybox) ash" >> "$out/bin/nixos-switch"
    echo "set -e" >> "$out/bin/nixos-switch"
    echo "nixos-rebuild boot" >> "$out/bin/nixos-switch"
    echo "/nix/var/nix/profiles/system/activate" >> "$out/bin/nixos-switch"
    chmod +x "$out/bin/nixos-switch"
  '';
}
