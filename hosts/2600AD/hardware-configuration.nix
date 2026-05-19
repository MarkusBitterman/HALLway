{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ZFS filesystem support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false; # required for hibernation (default is true)

  # ─────────────────────────────────────────────────────────────────────────
  # LUKS Encrypted Devices (Atari-themed labels)
  # ─────────────────────────────────────────────────────────────────────────
  # Layout:
  #   - /dev/sda (1TB SSD) → LUKS "CARTRIDGE" → ZFS pool "cartridge"
  #   - /dev/mmcblk0p1 (2GB eMMC) → FAT32 "/boot" labeled "COMBAT"
  #   - /dev/mmcblk0p2 (27GB eMMC) → LUKS "STELLA" → encrypted swap
  #
  # TPM2 auto-unlock can be enrolled after install via systemd-cryptenroll

  # Encrypted swap on eMMC (STELLA = Atari 2600 chip name)
  boot.initrd.luks.devices."stella_crypt" = {
    device = "/dev/disk/by-label/STELLA";
    # For TPM2 auto-unlock, add:
    # crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  # Encrypted root on SSD (CARTRIDGE = game cartridge)
  boot.initrd.luks.devices."cartridge_crypt" = {
    device = "/dev/disk/by-label/CARTRIDGE";
    # For TPM2 auto-unlock, add:
    # crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  # Boot partition on eMMC (FAT32, labeled COMBAT = Atari pack-in game)
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/COMBAT";
    fsType = "vfat";
    options = [
      "nofail"
      "noatime"
      "fmask=0077"
      "dmask=0077"
    ];
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
  fileSystems."/var" = {
    device = "cartridge/var";
    fsType = "zfs";
  };

  # Encrypted swap on eMMC partition 2
  swapDevices = [
    {
      device = "/dev/mapper/stella_crypt";
      priority = 100;
      # randomEncryption.enable = true; # Alternative: re-encrypt on each boot
      # ^ this would disable hibernation; keeping it crypted with TPM2 lets us hibernate
    }
  ];

  # Kernel modules for boot and hardware support
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sdhci_acpi"
    "sd_mod"
    "ccp"
    "sr_mod"
    "wireguard"
    "zfs"
    "amdgpu"
    "ahci"
    "snd_hda_intel"
    "snd_acp_pci"
    "snd_hda_codec"
    "snd_hda_codec_hdmi"
  ];
  boot.initrd.kernelModules = [
    "amdgpu" # Load AMD GPU support early to enable console
    "ahci" # SATA3 controller, M.2 drive
    "snd_hda_intel"
    "snd_acp_pci"
    "snd_hda_codec"
    "snd_hda_codec_hdmi"
  ];
  boot.kernelModules = [
    "kvm_amd" # Hardware virtualization support
    "i2c_piix4" # AMD SMBus / sensors
    "i2c_amd_mp2_pci" # Non-VGA unclassified device: Advanced Micro Devices, Inc. [AMD] Raven/Raven2/Renoir Non-Sensor Fusion Hub KMDF driver
  ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.kernelParams = [
    "vm.swappiness=80"
    "vm.page-cluster=0"
    "vm.dirty_background_ratio=10"
    "vm.dirty_ratio=20"
    "vm.watermark_scale_factor=20"
    "vm.vfs_cache_pressure=125"
    "vm.overcommit_memory=2"
    "vm.overcommit_ratio=70"

    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=40"
    "zswap.accept_threshold_percent=80"

    "video=card1-HDMI-A-1:1920x1080@100"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
    amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    clinfo
  ];

  # PCIe ASPM for power saving (optional)
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  services.udev.packages = [ pkgs.hwdata ];
}
