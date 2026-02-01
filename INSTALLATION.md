# HALLway Installation Guide

This guide covers installing HALLway on any supported hardware. For host-specific guides with exact commands, see:

- **2600AD** (Atari VCS 800): [`hosts/2600AD/INSTALLATION.md`](hosts/2600AD/INSTALLATION.md)

---

## Overview

HALLway uses a **flake-based NixOS installation** with:
- **LUKS encryption** for full disk encryption
- **ZFS** for the root filesystem (with datasets for `/`, `/home`, `/nix`)
- **Separate boot partition** (FAT32 for EFI)
- **Encrypted swap** (optional, for hibernation support)

## Prerequisites

- **NixOS Graphical Installer USB** (includes ZFS kernel modules)
- Target hardware with:
  - Boot device (can be separate from root, e.g., eMMC)
  - Root storage device (SSD recommended)
- Network access (to clone from GitHub)

---

## Installation Overview

1. **Boot** from NixOS Graphical Installer USB
2. **Partition** your disks (EFI boot, encrypted root, optional swap)
3. **Create** LUKS containers and ZFS pool with datasets
4. **Mount** filesystems to `/mnt/<hostname>`
5. **Clone** HALLway flake to `/mnt/<hostname>/etc/nixos`
6. **Run** `nixos-install --root /mnt/<hostname> --flake .#<hostname>`
7. **Reboot** into your new system

> **Note**: The installer runs from a RAM-based tmpfs with limited space (~3GB).
> The `nixos-install` command builds directly to your target ZFS store,
> bypassing this limitation. Do NOT run `nix build` for validation - use
> `nix flake check` instead (minimal disk usage).

---

## General Installation Steps

### 1. Boot from NixOS Installer USB

### 2. Partition Your Disks

You'll need:
- **EFI boot partition** (≥512MB, FAT32)
- **Encrypted root** (LUKS2 → ZFS pool)
- **Encrypted swap** (optional, for hibernation)

### 3. Create LUKS + ZFS

```bash
# Create LUKS container on root device
sudo cryptsetup luksFormat --type luks2 /dev/<root-device>
sudo cryptsetup open /dev/<root-device> cryptroot

# Create ZFS pool
sudo zpool create -f \
  -o ashift=12 \
  -o autotrim=on \
  -O acltype=posixacl \
  -O compression=lz4 \
  -O mountpoint=none \
  <poolname> /dev/mapper/cryptroot

# Create datasets
sudo zfs create -o mountpoint=legacy <poolname>/root
sudo zfs create -o mountpoint=legacy <poolname>/home
sudo zfs create -o mountpoint=legacy <poolname>/nix
```

### 4. Mount Filesystems

```bash
sudo mkdir -p /mnt/<hostname>/{boot,home,nix}
sudo mount -t zfs <poolname>/root /mnt/<hostname>
sudo mount -t zfs <poolname>/home /mnt/<hostname>/home
sudo mount -t zfs <poolname>/nix /mnt/<hostname>/nix
sudo mount /dev/<boot-partition> /mnt/<hostname>/boot
```

### 5. Clone HALLway

```bash
sudo mkdir -p /mnt/<hostname>/etc/nixos
cd /mnt/<hostname>/etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .
```

### 6. Create Your Host Configuration

Copy an existing host as a template:
```bash
cp -r hosts/2600AD hosts/<your-hostname>
```

Edit `hosts/<your-hostname>/hardware-configuration.nix` for your specific hardware.

Register your host in `flake.nix`:
```nix
nixosConfigurations."<your-hostname>" = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    hallwayModules.roles
    ./hosts/<your-hostname>/configuration.nix
    # ... home-manager, agenix, etc.
  ];
};
```

### 7. Install

```bash
sudo nixos-install \
  --root /mnt/<hostname> \
  --flake /mnt/<hostname>/etc/nixos#<hostname> \
  --no-root-password
```

> **Tip**: If using VS Code on the installer, there are pre-configured tasks:
> - `🧪 Validate` - Run `nix flake check` before installing
> - `🚀 Install` - Run the install with logging to `logs/`

### 8. Reboot

```bash
sudo umount -R /mnt/<hostname>
sudo zpool export <poolname>
sudo reboot
```

---

## Host-Specific Guides

For detailed, hardware-specific installation instructions:

| Host | Hardware | Guide |
|------|----------|-------|
| 2600AD | Atari VCS 800 | [`hosts/2600AD/INSTALLATION.md`](hosts/2600AD/INSTALLATION.md) |

---

## Post-Install

After first boot:

```bash
# Verify ZFS
sudo zpool status

# Rebuild after config changes
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

## Optional: TPM2 Auto-Unlock

Enroll TPM2 to avoid typing LUKS passphrases:

```bash
sudo systemd-cryptenroll --tpm2-device=auto /dev/<luks-device>
```

Then enable in `hardware-configuration.nix`:
```nix
boot.initrd.luks.devices."<name>".crypttabExtraOpts = [ "tpm2-device=auto" ];
```

---

## Troubleshooting

### "No space left on device" during install

The NixOS installer uses a ~3GB RAM-based tmpfs for `/nix/.rw-store`. This fills up quickly.

**Solutions:**
1. **Use `nixos-install` directly** - it builds to the target store, not tmpfs
2. **Run garbage collection**: `sudo nix-collect-garbage -d`
3. **Add swap** from a spare USB drive for overflow:
   ```bash
   sudo mkswap /dev/sdX1
   sudo swapon /dev/sdX1
   ```
4. **Avoid running `nix build`** - use `nix flake check` for validation instead

### "experimental feature 'flakes' is disabled"

The installer may not have flakes enabled by default. Use `nix-shell`:
```bash
cd /mnt/<hostname>/etc/nixos
nix-shell  # Enters shell with flakes enabled
nix flake check
```

Or set the environment variable:
```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```
