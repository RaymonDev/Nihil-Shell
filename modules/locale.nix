# locale.nix by poligle

{ config, lib, pkgs, ... }:
{
    time.timeZone = "Europe/Madrid";
    # Windows keeps the hardware clock in local time; match it so both OSes agree.
    time.hardwareClockInLocalTime = true;
    i18n.defaultLocale = "en_US.UTF-8";
    console = 
    {
        font = "Lat2-Terminus16";
        useXkbConfig = true;
    };
    services.xserver.xkb.layout = "es";
}