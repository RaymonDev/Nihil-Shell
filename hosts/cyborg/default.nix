# default.nix by poligle (cyborg)
#
# Fork for an MSI Cyborg 15 A13VF: Intel i7-13620H, Intel UHD + RTX 4060 Laptop,
# one 1920x1080 144 Hz panel, no fingerprint reader, Windows 11 on the same disk.
# hardware-configuration.nix is not in the repository: it is generated on the
# machine (see INSTALL.md) and has to be tracked by git before building.

{ config, lib, pkgs, ... }:
{
    imports = 
    [
        ./hardware-configuration.nix
        ../../modules/boot.nix
        ../../modules/network.nix
        ../../modules/locale.nix
        ../../modules/audio.nix
        ../../modules/hardware.nix
        ../../modules/nvidia.nix
        ../../modules/users.nix
        ../../modules/packages.nix
        ../../modules/hyprland.nix
        ../../modules/regreet.nix
        ../../modules/desktop.nix
        ../../modules/storage.nix
        ../../modules/services.nix
        ../../modules/nix.nix
        ../../modules/plymouth.nix
        ../../modules/stylix.nix
        ../../modules/virtualisation.nix
        ../../modules/wireshark.nix
        ../../modules/direnv.nix
        ../../modules/nihil.nix
    ];
    programs.zsh.enable = true;
    
    # Host-specific
    networking.hostName = "cyborg";

    # NIHIL: outputs at their logical size (after rotation), so the
    # dot-matrix wallpapers land on exact pixels. Hyprland runs the panel at
    # scale 1. To use an external monitor, add it here under its connector name
    # (see `hyprctl monitors`) with its real size.
    nihil =
    {
        primaryOutput = "eDP-1";
        wallpaper = "night";
        language = "en";
        outputs =
        {
            "eDP-1" = { width = 1920; height = 1080; };
        };

        # Nilo on the Radeon of the Ryzen, through Vulkan. Set enable = false
        # to drop it (and Ollama) altogether.
        nilo =
        {
            enable = false;
            acceleration = "vulkan";
            integratedGpu = true;
        };
    };
    system.stateVersion = "26.05";

    fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_:
    {
        options = [ "compress=zstd" "noatime" ];
    });

    services.btrfs.autoScrub =
    {
        enable = true;
        fileSystems = [ "/" ];
    };
}
