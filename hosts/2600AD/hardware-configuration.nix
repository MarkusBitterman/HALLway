{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ZFS filesystem support
  boot.supportedFilesystems = [ "zfs" ];

  # LUKS encrypted devices (Atari-themed labels for clarity)
  # Note: TPM2 auto-unlock is enrolled via systemd-cryptenroll after install
  boot.initrd.luks.devices."cryptswap" = {
    device = "/dev/disk/by-label/STELLA";  # Encrypted swap (named after the Atari 2600 chip)
    # For TPM2 auto-unlock, add:
    # crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-label/COMBAT";  # Encrypted root (named after the pack-in game)
    # For TPM2 auto-unlock, add:
    # crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
  
  # Boot partition on eMMC (FAT32, labeled BOOT)
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "nofail" "noatime" ];
    neededForBoot = true;
  };
  
  # ZFS filesystem definitions (pool named "cartridge")
  fileSystems."/" = {
    device = "cartridge/root";
    fsType = "zfs";
  };
  fileSystems."/home" = {
    device = "cartridge/home";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "cartridge/nix";
    fsType = "zfs";
  };
  
  # Encrypted swap on eMMC partition 2
  swapDevices = [
    { 
      device = "/dev/mapper/cryptswap";
      # randomEncryption.enable = true; # Alternative: re-encrypt on each boot
    }
  ];

  # Kernel modules for boot and hardware support
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" "sr_mod"
  ];
  boot.initrd.kernelModules = [
    "amdgpu"  # Load AMD GPU support early to enable console
  ];
  boot.kernelModules = [
    "kvm_amd"  # Hardware virtualization support
    "i2c_piix4" # AMD SMBus / sensors
  ];
  boot.extraModulePackages = [ ];

  # Platform and DHCP settings (from original hardware-configuration.nix pattern)
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # CPU microcode (AMD)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # AMD GPU hardware acceleration (from working config)
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
  ];
  hardware.graphics.enable32Bit = true;
  hardware.amdgpu.initrd.enable = true;
  hardware.amdgpu.amdvlk = {
    enable = true;
    support32Bit.enable = true;
    supportExperimental.enable = true;
  };

  # PCIe ASPM for power saving (optional)
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  services.udev.packages = [ pkgs.hwdata ];

  # Temporary working fallback if ZFS import fails:
  # fileSystems."/mnt/cryptroot" = {
  #   device = "/dev/mapper/cryptroot";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };

  # Note: actual module names may vary; this is a starting point.
}
