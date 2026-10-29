# Installing this fork on the MSI Cyborg 15 (dual boot with Windows 11)

This is a fork of [poligle/Nihil-Shell](https://github.com/poligle/Nihil-Shell) tuned for
an **MSI Cyborg 15 A13VF** (Intel i7-13620H, Intel UHD + RTX 4060 Laptop, 32 GB RAM,
1920x1080 144 Hz panel, Intel AX211 Wi-Fi, 1 TB Micron NVMe). The host is called `cyborg`.

The plan: erase only the old Ubuntu partition, install a minimal NixOS next to Windows,
then switch it to this flake. Windows' own partitions are never touched.

> Linux commands below run on the NixOS installer USB or on NixOS, never in Windows.
> `YOURUSER` is `ramon` in this fork. The commands assume the disk is `nvme0n1`, Windows'
> EFI partition is `p1` and Ubuntu is `p5`: **check this in Part 2 before formatting.**

## Part 0: Prepare in Windows

1. Back up what matters. Copy anything you need out of Ubuntu: its partition gets erased.
2. BitLocker: in an admin terminal run `manage-bde -status`. If C: is encrypted, save the
   recovery key from https://account.microsoft.com/devices/recoverykey on your phone.
3. Turn Fast Startup/hibernation off (admin PowerShell): `powercfg /h off`
4. Check Secure Boot with `msinfo32` ("Secure Boot State"). NixOS' installer and systemd-boot
   are unsigned, so you will switch it off in the BIOS (Part 1). Windows still runs;
   a few anti-cheats (e.g. Valorant) need it on.
5. Download the ISO (graphical, 26.05, the release this flake targets):
   https://channels.nixos.org/nixos-26.05/latest-nixos-graphical-x86_64-linux.iso
   and verify it against the `.sha256` file next to it:
   ```powershell
   Get-FileHash $env:USERPROFILE\Downloads\latest-nixos-graphical-x86_64-linux.iso -Algorithm SHA256
   ```
6. Write it to an 8 GB+ USB (it gets wiped) with Rufus: partition scheme **GPT**, target
   **UEFI**, "ISO image mode". If it will not boot, redo it in "DD image mode".
7. Have Wi-Fi details at hand (or an Ethernet cable), and this page open on your phone.

## Part 1: Boot the installer

1. Reboot and tap **F11** (MSI boot menu) or **Del** (BIOS). Pick the USB entry marked UEFI.
2. If it does not boot: in the BIOS (Del) disable **Secure Boot**. Do not change the storage
   mode, it can stop Windows from booting.
3. Pick the default NixOS entry. If the screen is black or garbled (the RTX uses the open
   `nouveau` driver here), reboot and choose the **nomodeset** entry.
4. Close the graphical installer window that appears and open a terminal. Then:
   ```text
   sudo -i
   setxkbmap es
   ping -c 2 nixos.org
   ```
   Connect Wi-Fi from the tray icon first if ping fails.

## Part 2: Identify the partitions (this protects Windows)

```text
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL /dev/nvme0n1
```

Expected (from Windows): a ~200 MB `vfat` EFI partition (`p1`), 16 MB MSR (`p2`), Windows
C: ~802 GB `ntfs` (`p3`), recovery ~0.9 GB `ntfs` (`p4`) and a ~150 GB `ext4` Ubuntu
partition (`p5`). **If your output differs, stop** and do not continue.

## Part 3: Format `p5` and mount

Only `p5` is formatted.

```text
mkfs.btrfs -L nixos -f /dev/nvme0n1p5
mount /dev/nvme0n1p5 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
umount /mnt
```

The flake expects exactly these four subvolumes, so nothing in it has to change:

```text
mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p5 /mnt
mkdir -p /mnt/home /mnt/nix /mnt/var/log /mnt/boot
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p5 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p5 /mnt/nix
mount -o subvol=@log,compress=zstd,noatime /dev/nvme0n1p5 /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
```

Back up the EFI partition, then remove only Ubuntu's boot files from it:

```text
cp -a /mnt/boot /mnt/esp-backup
ls /mnt/boot/EFI
rm -rf /mnt/boot/EFI/ubuntu
df -h /mnt/boot
```

`ls` should list `Boot`, `Microsoft` and `ubuntu`. Never delete `Microsoft` or `Boot`.
Keep at least 100 MB free in `df`.

## Part 4: Minimal install

```text
nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix
```

Check it lists `/`, `/home`, `/nix`, `/var/log` (with `subvol=`) and `/boot`. Then:

```text
cat > /mnt/etc/nixos/configuration.nix <<'EOF'
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cyborg";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Madrid";
  time.hardwareClockInLocalTime = true;

  users.users.ramon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
EOF
```

```text
nixos-install
nixos-enter --root /mnt -c 'passwd ramon'
reboot
```

`nixos-install` asks for a root password. Remove the USB when the screen goes black.

## Part 5: First boot and Windows check

1. systemd-boot should list **NixOS** and **Windows Boot Manager**. Boot Windows once to
   check it still works (enter the BitLocker key if asked), then reboot into NixOS.
2. Log in on the text console as `ramon` and connect to Wi-Fi:
   ```text
   nmcli device wifi connect "SSID" password "PASSWORD"
   ```

## Part 6: Switch to this flake

```text
git clone https://github.com/RaymonDev/Nihil-Shell ~/nixos-config
cd ~/nixos-config
cp /etc/nixos/hardware-configuration.nix hosts/cyborg/
git add -A
sudo nixos-rebuild switch --flake .#cyborg
```

* The flake only sees git-tracked files, which is why `git add -A` comes first.
* The first build downloads several GB and renders the wallpapers: 30-90 minutes. Stay on AC.
* Reboot afterwards: you should get the ReGreet login, then Hyprland.
* If the screen goes black after the switch, boot the previous generation from the menu.
  Then comment out `../../modules/nvidia.nix` in `hosts/cyborg/default.nix` to test without
  the NVIDIA module, and report what happened.
* Run something on the RTX with `nvidia-offload <command>`; `nvidia-offload nvidia-smi` checks it.

## Part 7: Cleanup

```text
efibootmgr
sudo efibootmgr -b 0001 -B
```

Delete only the **Ubuntu** entry (use its real number instead of `0001`). Keep "Windows Boot
Manager" and "Linux Boot Manager". After a few days of everything working: `sudo rm -rf /esp-backup`.

If Windows does not boot: copy `/esp-backup` back over the EFI partition or run Startup
Repair from a Windows USB. If NixOS does not boot: pick an older generation.

## What differs from upstream

* Host `thinkpad` -> `cyborg`; the author's `hardware-configuration.nix` is removed (yours is
  generated on the machine). User `poligle` -> `ramon`.
* `modules/nvidia.nix`: NVIDIA open driver with PRIME offload (Intel PCI 0:2:0, RTX PCI 1:0:0).
* One panel: `eDP-1` at 1920x1080@144; no HDMI/DP/vertical-monitor rules or ThinkPad
  trackpoint/Logitech device settings; keyboard model `pc105`, layout `es`.
* `modules/hardware.nix`: no fingerprint (PAM/fprintd) or mic-LED rules, adds Intel firmware and thermald.
  Hyprlock fingerprint is off; the mic LED script exits quietly when the LED does not exist.
* Language `en`, locale `en_US.UTF-8`, time zone `Europe/Madrid`, Windows-compatible RTC.
* Removed the Realtek Wi-Fi modprobe workaround (this PC has Intel Wi-Fi).
* Removed the MATLAB/FEKO/ADS sandbox (`home/engineering.nix` is no longer imported; re-add it
  to `home.nix` if you want it) and Octave. KiCad stays.
* `configurationLimit` 10 -> 3 (the EFI partition shared with Windows is small).
* `gh` uses HTTPS, git identity set in `home/cli.nix`. Website CNAME files removed.