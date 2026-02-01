# 2600AD: Two-Stage Installation Guide

**Target Hardware**: Atari VCS 800 with upgraded 1TB SSD  
**Current Constraint**: 32GB eMMC (running NixOS), 1TB SSD (empty), USB installer  
**Strategy**: Two-stage install with USB bridge

---

## Pre-Install Checklist

- [ ] HALLway flake is committed to GitHub (or accessible via USB)
- [ ] NixOS installer USB created and tested
- [ ] Current system backed up (optional but recommended)
- [ ] Disk layout verified with `sudo fdisk -l`

---

## Stage 1: Boot USB & Install NixOS to SSD

**Duration**: ~45-60 minutes  
**Running From**: NixOS Installer USB (sdc)  
**Target**: `/dev/sda` (1TB SSD)  
**Why USB?**: The installer has ZFS kernel modules pre-built for its kernel; your current eMMC system can't load ZFS dynamically.

### Step 1.1: Boot from USB

1. Insert NixOS installer USB into a USB port
2. Power cycle or reboot the Atari VCS 800
3. During boot, press **Esc** (or your BIOS key) to enter boot menu
4. Select the USB device (likely `sdc`)
5. Boot into NixOS live environment

### Step 1.2: Verify Disk Recognition

```bash
# List disks
sudo fdisk -l

# You should see:
# - /dev/mmcblk0 (32GB eMMC, currently running - DO NOT TOUCH)
# - /dev/sda (1TB SSD, target for installation)
# - /dev/sdb (58GB USB home - can ignore)
# - /dev/sdc (USB installer you just booted from - can ignore)
```

### Step 1.3: Prepare SSD with LUKS + ZFS

⚠️ **WARNING: This will erase `/dev/sda` completely**

```bash
# Create LUKS encrypted container
# Set a strong passphrase - WRITE IT DOWN IN YOUR VAULT
sudo cryptsetup luksFormat --type luks2 --label CARTRIDGE /dev/sda

# Open the encrypted container
sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt

# Create ZFS pool "cartridge"
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

# Create ZFS datasets
sudo zfs create -o mountpoint=legacy -o recordsize=128K cartridge/root
sudo zfs create -o mountpoint=legacy -o recordsize=1M cartridge/home
sudo zfs create -o mountpoint=legacy -o recordsize=16K cartridge/nix
```

**Verify**:
```bash
sudo zpool status cartridge
sudo zfs list -t filesystem
```

### Step 1.4: Mount Staging Area

```bash
# Create mount point
sudo mkdir -p /mnt/newroot/{home,nix,boot}

# Mount ZFS datasets
sudo mount -t zfs cartridge/root /mnt/newroot
sudo mount -t zfs cartridge/home /mnt/newroot/home
sudo mount -t zfs cartridge/nix /mnt/newroot/nix

# Verify mounts
mount | grep cartridge
```

### Step 1.5: Get HALLway Config

**Option A: Clone from GitHub** (recommended)

```bash
sudo mkdir -p /mnt/newroot/etc/nixos
cd /mnt/newroot/etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .
```

**Option B: From USB Device** (if offline)

```bash
# Find your USB device
lsblk

# Mount it (adjust sdb1 if needed)
sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb

# Copy HALLway
sudo mkdir -p /mnt/newroot/etc/nixos
sudo cp -r /mnt/usb/hallway/* /mnt/newroot/etc/nixos/

sudo umount /mnt/usb
```

### Step 1.6: Install NixOS to SSD

```bash
# Perform the installation
sudo nixos-install \
  --root /mnt/newroot \
  --flake '/mnt/newroot/etc/nixos#2600AD' \
  --no-root-passwd

# When prompted:
# - Enter password for bittermang user
# - Confirm root gets no password (we'll set it later)
```

**If installation fails**, check:
```bash
ls -la /mnt/newroot/etc/nixos/
ls -la /mnt/newroot/etc/nixos/hosts/2600AD/
sudo nixos-generate-config --root /mnt/newroot  # Generate fallback config
```

### Step 1.7: Verify Installation

```bash
# Check that system was installed
ls -la /mnt/newroot/etc/nixos
ls -la /mnt/newroot/boot
ls -la /mnt/newroot/nix/store | head

# Verify no bootloader was installed yet (we'll do that in Stage 2)
echo "✅ Stage 1 Complete - SSD has full NixOS installation!"
```

### Step 1.8: Unmount & Stay on USB

```bash
# Do NOT reboot yet - we're staying on USB for Stage 2

# Just unmount and export
sudo umount -R /mnt/newroot
sudo zpool export cartridge
sudo cryptsetup close cartridge_crypt

# Verify
mount | grep cartridge

echo "✅ SSD safely prepared - Ready for Stage 2"
```

---

## Stage 2: Reformat eMMC & Install Bootloader

**Duration**: ~20-30 minutes  
**Running From**: USB Installer (still running)  
**Targets**: `/dev/mmcblk0p1` (boot), `/dev/mmcblk0p2` (swap)

### Step 2.1: Verify SSD Installation

```bash
# Check that SSD has the full installation from Stage 1
sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt

# Import pool
sudo zpool import cartridge

# Verify datasets exist
sudo zfs list cartridge
sudo zfs list -r cartridge

# Mount briefly to confirm NixOS is installed
sudo mount -t zfs cartridge/root /mnt
ls -la /mnt/etc/nixos/  # Should see flake.nix, hosts/, modules/, etc.
sudo umount /mnt

# Keep pool imported but unmounted
sudo zpool export cartridge
```

### Step 2.2: Wipe & Repartition eMMC (DANGER ZONE)

⚠️ **This destroys the current eMMC OS - but USB keeps us alive and SSD has backup**

```bash
# Wipe eMMC partition table completely
sudo sgdisk --zap-all /dev/mmcblk0

# Create new partitions with Atari labels:
#   p1: 2GB EFI boot (labeled COMBAT)
#   p2: Remaining ~30GB encrypted swap (labeled STELLA)
sudo sgdisk -n 1:0:+2G -t 1:ef00 -c 1:"COMBAT" /dev/mmcblk0
sudo sgdisk -n 2:0:0 -t 2:8200 -c 2:"STELLA" /dev/mmcblk0

# Verify the new layout
sudo sgdisk -p /dev/mmcblk0
```

Expected output:
```
Number  Start (sector)    End (sector)  Size       Code  Name
   1           2048        4196351   2.0 GiB   EF00  COMBAT
   2        4196352       67108830   30.0 GiB  8200  STELLA
```

### Step 2.3: Format Boot & Swap Partitions

```bash
# Format boot partition as FAT32
sudo mkfs.fat -F 32 -n COMBAT /dev/mmcblk0p1

# Create encrypted swap with LUKS2
sudo cryptsetup luksFormat --type luks2 --label STELLA /dev/mmcblk0p2

# When prompted, enter passphrase for swap
# (Can be same or different from CARTRIDGE passphrase)

# Open the swap
sudo cryptsetup open /dev/disk/by-label/STELLA stella

# Format swap
sudo mkswap -L SWAP /dev/mapper/stella
```

### Step 2.4: Mount Everything Fresh

```bash
# Create temporary mount point
sudo mkdir -p /mnt/{boot,nix,home}

# Reopen SSD pool
sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt
sudo zpool import cartridge

# Mount ZFS datasets from SSD
sudo mount -t zfs cartridge/root /mnt
sudo mount -t zfs cartridge/home /mnt/home
sudo mount -t zfs cartridge/nix /mnt/nix

# Mount newly formatted boot partition
sudo mount /dev/disk/by-label/COMBAT /mnt/boot

# Activate swap
sudo swapon /dev/mapper/stella

# Verify all mounts
mount | grep -E "/mnt|cartridge"
swapon --show
```

### Step 2.5: Install Bootloader to eMMC

```bash
# The HALLway configuration already specifies GRUB
# We just need to let nixos-install generate it

cd /mnt/etc/nixos

# Install the bootloader to eMMC
sudo nixos-install \
  --root /mnt \
  --flake '.#2600AD' \
  --install-grub

# Set root password when prompted
```

### Step 2.6: Enroll TPM2 (Optional but Recommended)

```bash
# Chroot into new system to enroll TPM2
sudo nixos-enter --root /mnt

# Inside chroot:
systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/CARTRIDGE
systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/STELLA

# Verify enrollment
systemd-cryptenroll /dev/disk/by-label/CARTRIDGE

# Exit chroot
exit
```

### Step 2.7: Unmount & Prepare for Final Reboot

```bash
# Unmount everything cleanly
sudo umount -R /mnt
sudo swapoff /dev/mapper/stella
sudo cryptsetup close stella
sudo cryptsetup close cartridge_crypt
sudo zpool export cartridge

# Verify everything is unmounted
mount | grep cartridge

echo "✅ Stage 2 Complete - eMMC has bootloader, SSD has full system!"
```

### Step 2.8: Final Reboot

```bash
sudo reboot
```

**When you see the prompt:**
1. Remove the USB installer
2. Press Enter to continue boot

**First boot should:**
1. Boot from eMMC COMBAT partition (EFI)
2. Prompt for CARTRIDGE LUKS passphrase (or auto-unlock if TPM2 enrolled)
3. Mount root filesystem from SSD cartridge pool
4. Boot into NixOS with your HALLway configuration

---

## Post-Install Verification

After first boot into new system:

```bash
# Verify disk layout
sudo fdisk -l

# Check ZFS
sudo zpool status cartridge
sudo zfs list

# Check mounted filesystems
mount | grep -E "cartridge|SWAP"

# Verify swap
swapon --show

# Test gaming (optional)
# Launch a game!
```

---

## Passphrase Reference Card

Keep this safe (or in your password manager):

```
╔════════════════════════════════════════════════════════════╗
║  2600AD PASSPHRASES                                        ║
├════════════════════════════════════════════════════════════┤
║  CARTRIDGE (SSD root LUKS):      ________________________  ║
║  STELLA (eMMC swap LUKS):        ________________________  ║
║  root user:                      ________________________  ║
║  bittermang user:                ________________________  ║
╚════════════════════════════════════════════════════════════╝
```

---

## Troubleshooting

### "cryptsetup: command not found"
```bash
nix-shell -p cryptsetup zfs gitMinimal
```

### "ZFS pool already exists"
```bash
sudo zpool destroy cartridge
# Then retry creating the pool
```

### "Mount already in use"
```bash
sudo umount -R /mnt
sudo umount -R /newroot
```

### "Bootloader installation failed"
```bash
# Remount and try again
cd /mnt/etc/nixos
sudo nixos-install --flake .#2600AD --repair
```

### "Can't boot from eMMC after Stage 2"
Boot from USB again, verify:
```bash
sudo mount -t zfs cartridge/root /mnt
cd /mnt/boot
ls -la
```

Should see kernel, initrd, etc. If empty, bootloader didn't install.

---

## Space Optimization Tips

If running low on space during installation:

```bash
# Use gitMinimal instead of git
nix-shell -p gitMinimal

# Clean nix store before Stage 2
sudo nix-collect-garbage -d

# Check current usage
df -h
```

---

## Reference: Disk Layout After Installation

```
eMMC (/dev/mmcblk0)               SSD (/dev/sda)
├─ COMBAT (2GB boot)              └─ CARTRIDGE (LUKS)
│  └─ EFI files                       └─ cartridge (zpool)
└─ STELLA (swap, ~28GB)               ├─ root → /
   └─ SWAP                            ├─ home → /home
                                      └─ nix → /nix
```

---

## Ready to Begin?

1. **Pre-Installation**: Commit HALLway to GitHub or prepare USB with files
2. **Stage 1**: Run from current system - ✅ This installs NixOS to SSD
3. **USB Boot**: Reboot into installer
4. **Stage 2**: Run from USB - ✅ This reformats eMMC and installs bootloader
5. **Final Boot**: Remove USB, reboot into 2600AD!

Good luck! 🎮
