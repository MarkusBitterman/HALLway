# ╔════════════════╗
# ║  HALLway - Host: 2600AD                                                   ║
# ║  hardware-configuration.nix - Hardware, boot, filesystem declarations     ║
# ╚════════════════╝

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

  # ════════════════
  # BOOT
  # ════════════════

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false; # required for hibernation (default is true)

    # ─────────────────────────────────────────────────────────────────────────
    # LUKS Encrypted Devices (Atari-themed labels)
    # ─────────────────────────────────────────────────────────────────────────
    # Layout:
    #   - /dev/sda (1TB SSD)         → LUKS "CARTRIDGE" → ZFS pool "cartridge"
    #   - /dev/mmcblk0p1 (2GB eMMC)  → FAT32 "/boot" labeled "COMBAT"
    #   - /dev/mmcblk0p2 (27GB eMMC) → LUKS "STELLA"    → encrypted swap
    #
    # TPM2 auto-unlock can be enrolled after install via systemd-cryptenroll

    # STELLA = Atari 2600 Television Interface Adapter chip; encrypted swap on eMMC
    initrd.luks.devices."stella_crypt" = {
      device = "/dev/disk/by-label/STELLA";
      # For TPM2 auto-unlock, add:
      # crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    # CARTRIDGE = game cartridge; encrypted root on SSD
    initrd.luks.devices."cartridge_crypt" = {
      device = "/dev/disk/by-label/CARTRIDGE";
      # For TPM2 auto-unlock, add:
      # crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Kernel Modules
    # ─────────────────────────────────────────────────────────────────────────

    # Modules available to initrd (superset — includes everything in initrd.kernelModules)
    initrd.availableKernelModules = [
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

    # Modules forced to load in initrd
    initrd.kernelModules = [
      "amdgpu" # early console output via HDMI
      "ahci" # SATA/M.2 controller
      "snd_hda_intel"
      "snd_acp_pci"
      "snd_hda_codec"
      "snd_hda_codec_hdmi"
    ];

    # Post-boot kernel modules
    kernelModules = [
      "kvm_amd" # hardware virtualization
      "i2c_piix4" # AMD SMBus / sensor access
      "i2c_amd_mp2_pci" # AMD Sensor Fusion Hub
    ];

    extraModulePackages = with config.boot.kernelPackages; [ ];

    # ─────────────────────────────────────────────────────────────────────────
    # Kernel Parameters (hardware tuning)
    # ─────────────────────────────────────────────────────────────────────────
    # Boot/display params (quiet, splash, udev.log_level) live in configuration.nix;
    # NixOS merges both listOf str definitions at evaluation time.

    kernelParams = [
      # VM memory tuning — biased toward swap-backed workloads (ZFS + gaming)
      "vm.swappiness=100"
      "vm.page-cluster=0"
      "vm.dirty_background_ratio=5"
      "vm.dirty_ratio=10"
      "vm.watermark_scale_factor=10"
      "vm.vfs_cache_pressure=125"
      "vm.overcommit_memory=1"

      # zswap: compressed swap cache in RAM
      "zswap.enabled=0"
      # Force HDMI output mode before the display manager starts
      "video=card1-HDMI-A-1:1920x1080@100"
    ];
  };

  # ════════════════
  # FILESYSTEMS
  # ════════════════

  fileSystems = {
    # COMBAT = Atari pack-in game; FAT32 boot partition on eMMC
    "/boot" = {
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

    # ─────────────────────────────────────────────────────────────────────────
    # ZFS Datasets (pool: "cartridge")
    # ─────────────────────────────────────────────────────────────────────────

    "/" = {
      device = "cartridge/root";
      fsType = "zfs";
    };
    "/home" = {
      device = "cartridge/home";
      fsType = "zfs";
    };
    "/nix" = {
      device = "cartridge/nix";
      fsType = "zfs";
    };
    "/var" = {
      device = "cartridge/var";
      fsType = "zfs";
    };
  };

  # Encrypted swap — unlocked by the STELLA LUKS device above
  swapDevices = [
    {
      device = "/dev/mapper/stella_crypt";
      priority = 100;
      # randomEncryption.enable = true; # alternative: re-encrypt on each boot
      # ^ disables hibernation; LUKS-with-TPM2 is preferred to preserve it
    }
  ];

  # ════════════════
  # HARDWARE
  # ════════════════

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libglvnd # GLVND dispatch (libGL.so.1 — required by Steam/Proton)
        rocmPackages.clr.icd # ROCm ICD for OpenCL/HIP compute
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libglvnd # 32-bit GLVND for 32-bit games and Proton
      ];
    };
    amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    clinfo # OpenCL platform/device info
  ];

  # ════════════════
  # POWER
  # ════════════════

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand"; # CPU frequency scaling
  services.udev.packages = [ pkgs.hwdata ];
}
