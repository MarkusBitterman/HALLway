# 2600AD

> HALLway host — Atari VCS 800 gaming/media workstation

**Version**: 0.0.1
**Architecture**: x86_64

---

## Table of Contents

- [Quick Start](#quick-start)
- [Hardware](#hardware)
- [Installation](#installation)
  - [Standard](#standard)
  - [Full Step-by-Step](#full-step-by-step)
- [How to Contribute](#how-to-contribute)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Already installed?** Rebuild after config changes:

```bash
# Validate first
nix flake check

# Build and activate
sudo nixos-rebuild switch --flake .#2600AD
```

**Fresh install?** See [Installation](#installation) below.

---

## Hardware

| Component | Detail |
|-----------|--------|
| Board | Atari VCS 800 |
| CPU/GPU | AMD Ryzen R1606G APU (Radeon RX Vega 3, RADV) |
| Boot | eMMC `mmcblk0` — p1 (COMBAT, 2GB FAT32 EFI), p2 (STELLA, ~27GB LUKS swap) |
| Root | SSD `sda` — 1TB, LUKS2 labeled CARTRIDGE → ZFS pool `cartridge` |
| ZFS datasets | `cartridge/root`, `cartridge/home`, `cartridge/nix` |

### Disk Layout

```
eMMC (/dev/mmcblk0)                 SSD (/dev/sda)
├─ mmcblk0p1 (COMBAT, 2GB)          └─ CARTRIDGE (LUKS2)
│  └─ FAT32 /boot (EFI)                 └─ cartridge_crypt
└─ mmcblk0p2 (STELLA, ~27GB)                └─ cartridge (ZFS pool)
   └─ LUKS2 → stella                            ├─ root → /
      └─ swap                                   ├─ home → /home
                                                └─ nix → /nix
```

**Naming Theme**: Atari 2600 references — CARTRIDGE (where the game lives), COMBAT (pack-in game, first thing you boot), STELLA (the 2600's CPU chip).

## Role

Personal workstation. Primary use: development, gaming, media production.

## Configuration Model

- System config: [configuration.nix](configuration.nix)
- sops-nix secret mappings: [secrets.nix](secrets.nix)
- User environment (Home Manager): [home/bittermang.nix](home/bittermang.nix), [home/guest.nix](home/guest.nix)
- Hardware profile: [hardware-configuration.nix](hardware-configuration.nix) (auto-generated, do not edit)

## Key Features

- **ZFS on LUKS** — stable kernel pinned for ZFS module compatibility; optional TPM2 auto-unlock
- **Hibernation** — encrypted swap on eMMC, `boot.zfs.allowHibernation = true`
- **GNOME/GDM** — current display manager; Hyprland configured as alternate session
- **Steam + gamescope** — system-level install with Proton, proton-ge-bin, mangohud
- **WireGuard client** — `wg-hallspace` interface, peer: HALLpass.space hub at `10.23.11.80/24`
- **Syncthing client** — routes through HALLpass.space introducer/relay/discovery
- **iwd + systemd-networkd** — WiFi managed by iwd (no NetworkManager); `iwgtk` for tray

## Users

| User | UID | Description |
|------|-----|-------------|
| `bittermang` | 1000 | Primary user; packages + dotfiles in `home/bittermang.nix` |
| `guest` | 1001 | Ephemeral clean-room; tmpfs `/home/guest` wiped on reboot |

## Placeholder Values

These must be replaced before WireGuard and Syncthing are functional:

| Placeholder | Location | How to get it |
|-------------|----------|---------------|
| `HALLPASS_WG_PUBLIC_KEY` | `configuration.nix` | `wg pubkey` from HALLpass.space keygen |
| `HALLPASS_SYNCTHING_DEVICE_ID` | `configuration.nix` | `syncthing cli show system` on HALLpass.space |
| `DISCOVERY_SERVER_ID` | `configuration.nix` | `journalctl -u syncthing-discovery` on HALLpass.space |
| `RELAY_SERVER_ID` | `configuration.nix` | `journalctl -u syncthing.service` on HALLpass.space |
| `PHONE_SYNCTHING_DEVICE_ID` | `configuration.nix` | Syncthing app on phone |

See [../../docs/secrets.md](../../docs/secrets.md) for the full secrets lifecycle.

---

## Installation

**Target Hardware**: Atari VCS 800 with upgraded 1TB NVMe SSD
**Install From**: NixOS Graphical Installer USB (25.11+)
**Filesystem**: ZFS on LUKS2 with separate eMMC boot

### Standard

The generic flow from the [main README](../../README.md#installation) applies. This host uses:
- Pool name: `cartridge`
- Boot partition: `/dev/mmcblk0p1` (COMBAT)
- Root LUKS device: `/dev/sda` (CARTRIDGE)
- Swap LUKS device: `/dev/mmcblk0p2` (STELLA)

### Full Step-by-Step

#### Pre-Install Checklist

- [ ] NixOS installer USB created and tested
- [ ] LUKS passphrases chosen and recorded in vault
- [ ] Network access available (for GitHub clone)

#### Step 1: Boot from USB Installer

1. Insert NixOS installer USB
2. Power on/reboot the Atari VCS 800
3. Press **Esc** during boot to enter boot menu
4. Select USB device
5. Boot into NixOS live environment

Verify disks:

```bash
sudo fdisk -l
# Expected:
# /dev/sda      - 1TB SSD (target for CARTRIDGE)
# /dev/mmcblk0  - 32GB eMMC (for COMBAT boot + STELLA swap)
```

#### Step 2: Partition eMMC

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

#### Step 3: Prepare SSD with LUKS + ZFS

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

Verify:

```bash
sudo zpool status cartridge
sudo zfs list -t filesystem
```

#### Step 4: Mount Everything

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

#### Step 5: Clone HALLway Configuration

```bash
sudo mkdir -p /mnt/2600AD/etc/nixos
cd /mnt/2600AD/etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .
```

#### Step 5.5: Create sops Secrets

```bash
cd /mnt/2600AD/etc/nixos
nix develop  # Provides sops command

# Create admin age key (first time only)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Note the public key for .sops.yaml
```

**Secrets Checklist:**

All secrets are stored in `hosts/2600AD/secrets.yaml`:

| Key | Format | Required? |
|-----|--------|-----------|
| `ssh_key_github` | SSH private key | Yes |
| `ssh_key_hobbs` | SSH private key | Optional |
| `ssh_key_hallpass` | SSH private key | Yes (for VPS access) |
| `github_token` | GitHub PAT | Optional |
| `gpg_key` | GPG private key (armor export) | Optional |
| `wg_2600ad_privatekey` | WireGuard private key (44 chars) | Yes |
| `wg_hallspace_psk` | WireGuard PSK (44 chars) | Yes |
| `syncthing_gui_pass` | Password | Yes |
| `wifi_home` | iwd format (see below) | Yes (for WiFi) |

**Edit secrets** (opens editor with decrypted YAML, re-encrypts on save):

```bash
sops hosts/2600AD/secrets.yaml
```

**Example secrets.yaml structure:**

```yaml
ssh_key_github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...your key content...
    -----END OPENSSH PRIVATE KEY-----
github_token: ghp_xxxxxxxxxxxxx
wg_2600ad_privatekey: base64-wireguard-key
syncthing_gui_pass: your-password
wifi_home: |
    [Security]
    Passphrase=your-wifi-password-here
```

**WireGuard key generation:**

```bash
# Generate private key (keep secret)
wg genkey > privatekey

# Derive public key (share with peers)
cat privatekey | wg pubkey > publickey

# Generate preshared key (same key on both peers)
wg genpsk > psk
```

**After creating secrets**, stage for git:

```bash
git add hosts/2600AD/secrets.yaml
```

#### Step 6: Install NixOS

**Option A: VS Code** (if available on installer)

1. **Validate first**: Ctrl+Shift+P → "Run Test Task"
2. **Install**: Ctrl+Shift+B
3. **Monitor**: Logs saved to `logs/install-<timestamp>.log`

**Option B: Command Line**

```bash
sudo nixos-install \
  --root /mnt/2600AD \
  --flake /mnt/2600AD/etc/nixos#2600AD \
  --no-root-password

# When prompted: Set password for bittermang user
```

#### Step 7: Finalize

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

#### First Boot

1. System boots from eMMC (COMBAT partition)
2. Enter LUKS passphrase for CARTRIDGE (SSD)
3. Enter LUKS passphrase for STELLA (swap)
4. NixOS boots with HALLway configuration

#### Post-Install: TPM2 Auto-Unlock (Optional)

```bash
# Enroll both LUKS volumes
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/CARTRIDGE
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/STELLA

# Verify enrollment
sudo systemd-cryptenroll /dev/disk/by-label/CARTRIDGE
```

Then uncomment TPM2 lines in `hardware-configuration.nix`:

```nix
boot.initrd.luks.devices."stella".crypttabExtraOpts = [ "tpm2-device=auto" ];
boot.initrd.luks.devices."cartridge_crypt".crypttabExtraOpts = [ "tpm2-device=auto" ];
```

---

## How to Contribute

See [CONTRIBUTING.md](../../CONTRIBUTING.md) in the repository root for:

- Dev environment setup
- Code style guidelines
- Pull request process

---

## Troubleshooting

### ZFS pool already imported

```bash
sudo zpool export cartridge
```

### Mount point busy

```bash
sudo umount -R /mnt/2600AD
sudo fuser -km /mnt/2600AD  # Kill processes using mount
```

### LUKS device already open

```bash
sudo cryptsetup close cartridge_crypt
sudo cryptsetup close stella
```

### Home Manager XDG Portal Error

Already fixed in `configuration.nix`:

```nix
environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
```

### Package Renames/Removals

Common fixes:
- `rofi-wayland` → `rofi`
- `onlyoffice-bin` → `onlyoffice-desktopeditors`
- `amdvlk` → removed (RADV is default)

### Verify Hardware After First Boot

```bash
# Check swap activation
swapon --show

# Check kernel modules
lsmod | grep -E "snd_hda|amdgpu"

# Check boot logs for errors
journalctl -b | grep -iE "failed|error" | head -20
```

---

## Known Issues

- `nix-ld.libraries` block needs cleanup/annotation
- `handbrake`, `kdePackages.kdenlive`, `ffmpeg` commented out pending GCC 15 build fix

---

## Passphrase Reference Card

```
+------------------------------------------------------------+
|  2600AD PASSPHRASES                                        |
+------------------------------------------------------------+
|  CARTRIDGE (SSD root):     ______________________________  |
|  STELLA (eMMC swap):       ______________________________  |
|  bittermang user:          ______________________________  |
+------------------------------------------------------------+
```
