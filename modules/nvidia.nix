# nvidia.nix by poligle (cyborg: Intel UHD + RTX 4060 Laptop, PRIME offload)
#
# The desktop runs on the Intel iGPU; the RTX is powered down until an app asks
# for it with `nvidia-offload <command>` (or Steam's launch option).
# Bus IDs from Windows: Intel at PCI 0:2.0, NVIDIA at PCI 1:0.0.

{ config, lib, pkgs, ... }:
{
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia =
    {
        modesetting.enable = true;
        open = true;                    # Ada (RTX 40) supports the open kernel modules
        nvidiaSettings = false;
        powerManagement.enable = true;
        powerManagement.finegrained = true;

        prime =
        {
            offload.enable = true;
            offload.enableOffloadCmd = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };
}