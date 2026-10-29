# users.nix by poligle

{ config, lib, pkgs, ... }:
{
    users.users.ramon = 
    {
        isNormalUser = true;
        description = "Ramon";
        shell = pkgs.zsh;
        extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" "wireshark" ];
        packages = with pkgs; 
        [
            tree
        ];
    };
}