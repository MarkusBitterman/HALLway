# 2600AD: Installation Guide

**Target Hardware**: Atari VCS 800 with upgraded 1TB SSD
**Install From**: NixOS Graphical Installer USB
**Strategy**: USB-based installation with ZFS on LUKS

---

## Disk Layout

| Device | Size | Purpose | Label | Filesystem |
|--------|------|---------|-------|------------|
| `/dev/sda` | 1TB SSD | Encrypted root (LUKS → ZFS) | `CARTRIDGE` | LUKS2 → ZFS |
| `/dev/mmcblk0p1` | 2GB eMMC | EFI boot partition | `COMBAT` | FAT32 |
| `/dev/mmcblk0p2` | ~27GB eMMC | Encrypted swap (LUKS) | `STELLA` | LUKS2 → swap |

**Naming Theme**: Atari 2600 references
- **CARTRIDGE** = Game cartridge (where the game/OS lives)
- **COMBAT** = Pack-in game (first thing you boot)
- **STELLA** = The 2600's CPU chip (handles the work)

---

## Pre-Install Checklist

- [ ] NixOS installer USB created and tested
- [ ] Disk layout planned (see above)
- [ ] LUKS passphrases chosen and recorded in vault
- [ ] Network access available (for GitHub clone)

---

## Step 1: Boot from USB Installer

1. Insert NixOS installer USB
2. Power on/reboot the Atari VCS 800
3. Press **Esc** during boot to enter boot menu
4. Select USB device
5. Boot into NixOS live environment

### Verify Disks

```bash
sudo fdisk -l

# Expected:
# /dev/sda      - 1TB SSD (target for CARTRIDGE)
# /dev/mmcblk0  - 32GB eMMC (for COMBAT boot + STELLA swap)
# /dev/sdc      - USB installer (ignore)
```

---

## Step 2: Partition eMMC

```bash
# Wipe eMMC partition table
sudo sgdisk --zap-all /dev/mmcblk0

# Create partitions:
#   p1: 2GB EFI boot (COMBAT)
#   p2: Remaining ~27GB encrypted swap (STELLA)
sudo sgdisk -n 1:0:+2G -t 1:ef00 -c 1:"COMBAT" /dev/mmcblk0
sudo sgdisk -n 2:0:0 -t 2:8200 -c 2:"STELLA" /dev/mmcblk0

# Format boot partition
sudo mkfs.fat -F 32 -n COMBAT /dev/mmcblk0p1

# Setup encrypted swap
sudo cryptsetup luksFormat --type luks2 --label STELLA /dev/mmcblk0p2
sudo cryptsetup open /dev/disk/by-label/STELLA stella
sudo mkswap -L SWAP /dev/mapper/stella
```

---

## Step 3: Prepare SSD with LUKS + ZFS

⚠️ **WARNING: This will erase `/dev/sda` completely**

```bash
# Create LUKS encrypted container
sudo cryptsetup luksFormat --type luks2 --label CARTRIDGE /dev/sda

# Open the encrypted container
sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt

# Create ZFS pool
sudo zpool create -f \
  -o ashift=12 \
  -o autotrim=on \
  -O acltype=posixacl \
  -O atime=off \
  -O compression=lz4 \
  -O dnodesize=auto \
  -O normalization=formD \
  -O relatime=on \
  -O xattr=sa \
  -O mountpoint=none \
  cartridge /dev/mapper/cartridge_crypt

# Create ZFS datasets (with optimized recordsizes)
sudo zfs create -o mountpoint=legacy -o recordsize=128K cartridge/root
sudo zfs create -o mountpoint=legacy -o recordsize=1M cartridge/home
sudo zfs create -o mountpoint=legacy -o recordsize=16K cartridge/nix
```

**Verify**:
```bash
sudo zpool status cartridge
sudo zfs list -t filesystem
```

---

## Step 4: Mount Everything

```bash
# Create mount structure
sudo mkdir -p /mnt/2600AD/{boot,home,nix}

# Mount ZFS datasets
sudo mount -t zfs cartridge/root /mnt/2600AD
sudo mkdir -p /mnt/2600AD/{boot,home,nix}
sudo mount -t zfs cartridge/home /mnt/2600AD/home
sudo mount -t zfs cartridge/nix /mnt/2600AD/nix

# Mount boot partition
sudo mount /dev/disk/by-label/COMBAT /mnt/2600AD/boot

# Enable swap
sudo swapon /dev/mapper/stella

# Verify
mount | grep 2600AD
swapon --show
```

---

## Step 5: Clone HALLway Configuration

```bash
sudo mkdir -p /mnt/2600AD/etc/nixos
cd /mnt/2600AD/etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .
```

---

## Step 6: Install NixOS

```bash
sudo nixos-install \
  --root /mnt/2600AD \
  --flake /mnt/2600AD/etc/nixos#2600AD \
  --no-root-password

# When prompted: Set password for bittermang user
```

**If errors occur**, check `error.txt` in the repo for common fixes.

---

## Step 7: Finalize

```bash
# Unmount everything
sudo umount -R /mnt/2600AD
sudo swapoff /dev/mapper/stella
sudo zpool export cartridge
sudo cryptsetup close stella
sudo cryptsetup close cartridge_crypt

# Reboot
sudo reboot
```

Remove USB when prompted.

---

## First Boot

1. System boots from eMMC (COMBAT partition)
2. Enter LUKS passphrase for CARTRIDGE (SSD)
3. Enter LUKS passphrase for STELLA (swap)
4. NixOS boots with HALLway configuration

---

## Post-Install: TPM2 Auto-Unlock (Optional)

Enroll TPM2 to avoid typing passphrases on every boot:

```bash
# Enroll both LUKS volumes
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/CARTRIDGE
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/STELLA

# Verify enrollment
sudo systemd-cryptenroll /dev/disk/by-label/CARTRIDGE
```

Then uncomment the TPM2 lines in `hardware-configuration.nix`:
```nix
boot.initrd.luks.devices."stella".crypttabExtraOpts = [ "tpm2-device=auto" ];
boot.initrd.luks.devices."cartridge_crypt".crypttabExtraOpts = [ "tpm2-device=auto" ];
```

---

## Troubleshooting

### "ZFS pool already imported"
```bash
sudo zpool export cartridge
```

### "Mount point busy"
```bash
sudo umount -R /mnt/2600AD
sudo fuser -km /mnt/2600AD  # Kill processes using mount
```

### "LUKS device already open"
```bash
sudo cryptsetup close cartridge_crypt
sudo cryptsetup close stella
```

### Home Manager XDG Portal Error
Already fixed in `hosts/2600AD/configuration.nix`:
```nix
environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
```

### Package Renames/Removals
Check `error.txt` for known fixes. Common ones:
- `rofi-wayland` → `rofi`
- `onlyoffice-bin` → `onlyoffice-desktopeditors`
- `amdvlk` → removed (RADV is default)

---

## Passphrase Reference Card

```
╔════════════════════════════════════════════════════════════╗
║  2600AD PASSPHRASES                                        ║
├────────────────────────────────────────────────────────────┤
║  CARTRIDGE (SSD root):     ______________________________  ║
║  STELLA (eMMC swap):       ______________________________  ║
║  bittermang user:          ______________________________  ║
╚════════════════════════════════════════════════════════════╝
```

---

## Final Disk Layout

```
eMMC (/dev/mmcblk0)                 SSD (/dev/sda)
├─ mmcblk0p1 (COMBAT, 2GB)          └─ CARTRIDGE (LUKS2)
│  └─ FAT32 /boot (EFI)                 └─ cartridge_crypt
└─ mmcblk0p2 (STELLA, ~27GB)                └─ cartridge (ZFS pool)
   └─ LUKS2 → stella                            ├─ root → /
      └─ swap                                   ├─ home → /home
                                                └─ nix → /nix
```
