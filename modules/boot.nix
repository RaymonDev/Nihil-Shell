# boot.nix by poligle

{ config, lib, pkgs, ... }:
{
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 3;   # the shared Windows ESP is small
    boot.supportedFilesystems = [ "exfat" "ext4" "vfat" ];
    boot.initrd.systemd.enable = true;
}
