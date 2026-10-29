# hardware.nix by poligle (cyborg: no fingerprint reader, no ThinkPad LEDs)

{ config, lib, pkgs, ... }:
{
    services.libinput.enable = true;
    services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
    };
    zramSwap.enable = true;
    hardware.graphics.enable = true;

    # Intel AX211 Wi-Fi/Bluetooth need the redistributable firmware blobs.
    hardware.enableRedistributableFirmware = true;
    services.thermald.enable = true;
}