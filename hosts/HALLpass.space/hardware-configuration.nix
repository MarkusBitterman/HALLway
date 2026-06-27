# ╔════════════════╗
# ║  HALLway - Host: HALLpass.space                                           ║
# ║  hardware-configuration.nix - Hardware, boot, filesystem declarations     ║
# ╚════════════════╝

{ lib, ... }:

{
  imports = [ ];

  # ════════════════
  # BOOT
  # ════════════════

  boot = {
    # virtio_pci / virtio_blk required for Hyper-V virtual disk and NIC
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  # ════════════════
  # FILESYSTEMS
  # ════════════════

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d5615f9a-4c91-4865-b4cf-d95f22b9c31d";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2 GiB overflow beyond zramSwap
    }
  ];

  # ════════════════
  # HARDWARE
  # ════════════════

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.hypervGuest.enable = true; # VPS is Hyper-V hosted
}
