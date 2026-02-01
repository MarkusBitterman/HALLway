# HALLway

> *An OS concept by Matthew Hall*

**Version**: 0.0.1 (codename: **2600AD**)  
**Target Hardware**: Atari VCS 800

---

## What is HALLway?

HALLway is a declarative, role-based operating system concept built on NixOS. The goal is to create a system where:

- **Users are defined by capabilities, not just permissions**
- **Environments are reproducible and composable**
- **Guest sessions are truly ephemeral (clean room)**
- **The system is self-documenting and auditable**

This repository (`2600AD`) is the first implementation - a gaming/media workstation built on an Atari VCS 800.

---

## 2600AD: The First HALLway

This is a NixOS configuration for an Atari VCS 800 system, with a 1TB SATA3 M.2 SSD that meets the following:

- Zen kernel and ZFS root
- Steam with gamescope
- TPM2‑backed LUKS and secure boot
- zram + swap for hibernate
- Network via systemd‑networkd
- Age secrets (via agenix)
- Home‑Manager integration

## Flake-Based Configuration

This configuration uses **Nix flakes** for reproducible builds. Benefits include:
- **Pinned versions**: `flake.lock` pins exact versions of nixpkgs, Home Manager, and agenix
- **No channels needed**: Dependencies declared in `flake.nix`, not system channels
- **Reproducible**: Same inputs always produce same outputs
- **Easy updates**: `nix flake update` updates all dependencies at once
- **Using unstable**: nixpkgs-unstable for latest packages, targeting NixOS 25.11

**References:**
- [NixOS Installation Guide](https://nixos.wiki/wiki/NixOS_Installation_Guide)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Wiki](https://nixos.wiki/wiki/Home_Manager)
- [agenix GitHub](https://github.com/ryantm/agenix)
- [agenix Wiki](https://nixos.wiki/wiki/Agenix)

## Creating USB Installation Media

Download and create the NixOS installation USB before beginning the installation process:

```bash
# Download NixOS unstable ISO (graphical installer recommended for easier setup)
wget -c https://channels.nixos.org/nixos-unstable/latest-nixos-gnome-x86_64-linux.iso
# Or minimal ISO if preferred:
# wget -c https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

# Create bootable USB (replace /dev/sdX with your USB device)
# Find your device with: lsblk
# WARNING: This will destroy all data on the USB drive
sudo dd if=latest-nixos-gnome-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fdatasync

# Alternative using cp (simpler, works on NixOS ISOs)
sudo cp latest-nixos-gnome-x86_64-linux.iso /dev/sdX
sync
```

### Alternative: Use Balena Etcher or Ventoy
For a more user-friendly approach, you can use:
- **Balena Etcher**: GUI tool for creating bootable USB drives
- **Ventoy**: Multi-boot USB solution that supports drag-and-drop ISO files

### UEFI/Secure Boot Note
The NixOS installer ISO is **not signed**, so you must **disable Secure Boot** in your BIOS/UEFI settings before booting from the USB drive.

### NixOS Installation Reference
For additional information, consult:
- [NixOS Wiki Installation Guide](https://nixos.wiki/wiki/NixOS_Installation_Guide) - Community guide with practical tips
- [NixOS Manual Installation](https://nixos.org/manual/nixos/stable/index.html#sec-installation) - Official documentation

## Key Generation and Secrets Management

Before installation, generate the necessary keys and set up agenix for secrets management.

**Important**: agenix uses SSH public keys to encrypt secrets. Secrets are decrypted at runtime using the corresponding private key (typically the system's SSH host key or your user's SSH key).

### Generate SSH Keys
```bash
# Generate an SSH key for the new system (ed25519 recommended)
ssh-keygen -t ed25519 -C "bittermang@2600AD" -f ~/.ssh/2600ad_ed25519

# Generate a GitHub-specific SSH key (if different from above)
ssh-keygen -t ed25519 -C "bittermang@duck.com" -f ~/.ssh/github_ed25519

# View the public key (you'll need this for agenix secrets.nix)
cat ~/.ssh/2600ad_ed25519.pub
```

### Generate GPG Keys
```bash
# Generate a GPG key for signing commits
gpg --full-generate-key
# Choose:
# - (1) RSA and RSA
# - 4096 bit key size  
# - Key does not expire (or set expiration as preferred)
# - Real name: Matthew Hall
# - Email: bittermang@duck.com

# Export the public key for GitHub
gpg --armor --export bittermang@duck.com > ~/gpg_public_key.asc

# List keys to get the key ID (look for the long hex string after 'sec')
gpg --list-secret-keys --keyid-format=long
```

### Set up agenix for Secrets Management

agenix requires a `secrets.nix` file that defines which public keys can decrypt each secret. This is separate from the NixOS module configuration.

```bash
# Install agenix temporarily for key management
nix-shell -p age agenix

# Create a secrets directory for encrypted .age files
mkdir -p ~/nix/secrets

# Get the public key from your SSH key (for encrypting secrets)
# Option 1: Use ssh-to-age to convert SSH public key to age format
nix-shell -p ssh-to-age -c "ssh-to-age < ~/.ssh/2600ad_ed25519.pub"
# This outputs something like: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Option 2: Generate a dedicated age keypair
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/keys.txt
# The public key is printed and also in the file as a comment
```

### Create the agenix secrets.nix file

Create `~/nix/secrets/secrets.nix` (this is the **rule file** for agenix CLI, NOT the NixOS module):

```nix
# This file defines which public keys can decrypt each secret
# It is used by the `agenix` CLI tool, not imported into NixOS directly
let
  # User SSH public keys (converted to age format with ssh-to-age)
  bittermang = "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  
  # System SSH host key (get this after first boot with: ssh-keyscan localhost)
  # Or use the ed25519 host key: ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
  system2600ad = "age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";
  
  allKeys = [ bittermang system2600ad ];
in
{
  "ssh_key.age".publicKeys = allKeys;
  "github_token.age".publicKeys = [ bittermang ];
  "gpg_key.age".publicKeys = [ bittermang ];
}
```

### Encrypt Secrets with agenix
```bash
# Navigate to secrets directory  
cd ~/nix/secrets

# Set RULES to point to your secrets.nix
export RULES=./secrets.nix

# Create/edit encrypted secrets (opens $EDITOR)
agenix -e ssh_key.age
agenix -e github_token.age

# To encrypt GPG private key
gpg --armor --export-secret-keys bittermang@duck.com > /tmp/gpg.key
agenix -e gpg_key.age  # paste content from /tmp/gpg.key
rm /tmp/gpg.key

# Verify secrets were created
ls -la *.age
```

### NixOS Module Configuration for agenix

The `secrets.nix` in your NixOS config directory (not the same as the agenix rules file above) defines how secrets are mounted. This is already set up in the repo:

```nix
# ~/nix/secrets.nix (NixOS module - imported in configuration.nix)
{ config, ... }: {
  age.secrets."ssh_key" = {
    file = ./secrets/ssh_key.age;
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };
  # ... other secrets
}
```

### Home Manager Integration Notes

The `home/bittermang.nix` already has SSH and Git configuration. After decrypting secrets, update the SSH matchBlock to reference the decrypted secret path:

```nix
# In home/bittermang.nix - SSH configuration  
programs.ssh = {
  enable = true;
  matchBlocks."github.com" = {
    # After agenix is working, you can reference the secret path:
    # identityFile = config.age.secrets.ssh_key.path;
    # For now, use a direct path:
    identityFile = "~/.ssh/github_ed25519";
    identitiesOnly = true;
    user = "git";
  };
};

# Git configuration - update after getting GPG key ID
programs.git = {
  enable = true;
  userName = "Markus Bitterman";
  userEmail = "bittermang@duck.com";
  signing = {
    key = null; # Set to your GPG key ID, e.g., "ABCD1234EFGH5678"
    signByDefault = false; # Set to true after configuring GPG
  };
};
```

## Initial partitioning steps

This section documents the complete process for creating a fresh NixOS installation on the Atari VCS 800 with ZFS root, TPM2-backed LUKS encryption, and proper swap configuration.

### Disk Layout
- **eMMC** (`/dev/mmcblk0`) - ~32GB internal storage
  1. `mmcblk0p1`: `/boot` partition (~2GB) - FAT32, labeled "COMBAT" (Atari 2600 pack-in game)
  2. `mmcblk0p2`: Encrypted swap (~30GB) - LUKS labeled "STELLA" (Atari 2600 CPU chip), mapper: "stella"
- **SSD** (`/dev/sda`) - 1TB SATA M.2
  1. Entire disk - LUKS labeled "CARTRIDGE" (Atari 2600 game cartridge), mapper: "cartridge_crypt", contains ZFS pool "cartridge"

### Prerequisites
- NixOS installation USB media (see USB creation steps above)
- Atari VCS 800 with 1TB M.2 SSD installed
- Working TPM2 chip in the system

### Step 1: Boot from USB and prepare environment
Boot from the NixOS USB installer and set up the environment:
```bash
# Connect to the internet first (use nmtui for WiFi on graphical ISO)
# Verify connectivity
ping -c 3 nixos.org

# Enable experimental features for the installer session
export NIX_CONFIG="experimental-features = nix-command flakes"

# Install necessary tools for partitioning and encryption
nix-shell -p gptfdisk cryptsetup zfs
```

### Step 2: Partition the eMMC
```bash
# Clear any existing partition table on eMMC
sgdisk --zap-all /dev/mmcblk0

# Create GPT partition table:
# 1. EFI boot partition (2GB) - extra space for kernels/ISOs
# 2. Swap partition (remaining ~30GB)
sgdisk -n 1:0:+2G -t 1:ef00 -c 1:"EFI System" /dev/mmcblk0
sgdisk -n 2:0:0 -t 2:8200 -c 2:"swap" /dev/mmcblk0

# Verify partition layout
sgdisk -p /dev/mmcblk0
```

### Step 3: Format boot partition and set up encrypted swap
```bash
# Format the EFI boot partition with label COMBAT (Atari 2600 pack-in game)
mkfs.fat -F 32 -n COMBAT /dev/mmcblk0p1

# Create LUKS encrypted swap partition with label STELLA (Atari 2600 CPU chip)
cryptsetup luksFormat --type luks2 --label STELLA /dev/mmcblk0p2

# Open encrypted swap using label and format inner volume
cryptsetup open /dev/disk/by-label/STELLA stella
mkswap -L SWAP /dev/mapper/stella
```

### Step 4: Create LUKS container and ZFS pool on SSD

```bash
# Create LUKS encrypted container on the entire SSD with label CARTRIDGE (Atari 2600 game cartridge)
# You will be prompted to set a passphrase - REMEMBER THIS!
cryptsetup luksFormat --type luks2 --label CARTRIDGE /dev/sda

# Open the encrypted container using label (mapper name: cartridge_crypt)
cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt

# Create ZFS pool named "cartridge" on the encrypted device
# -O mountpoint=none: Don't auto-mount, we'll use legacy mounts for NixOS
# -O atime=off: Improves performance
# -O compression=lz4: Enable compression (lz4 is fast; zstd for better compression)
zpool create -f -O mountpoint=none -O atime=off -O compression=lz4 -O xattr=sa -O acltype=posixacl cartridge /dev/mapper/cartridge_crypt

# Create ZFS datasets with optimized settings
zfs create -o mountpoint=legacy cartridge/root
zfs create -o mountpoint=legacy cartridge/home
zfs create -o mountpoint=legacy -o recordsize=16K cartridge/nix

# Set bootfs property for ZFS root (helps with boot)
zpool set bootfs=cartridge/root cartridge
```

### Step 5: Mount filesystems for installation
```bash
# Mount the ZFS root
mount -t zfs cartridge/root /mnt

# Create mount points
mkdir -p /mnt/{home,nix,boot}

# Mount the ZFS datasets
mount -t zfs cartridge/home /mnt/home
mount -t zfs cartridge/nix /mnt/nix

# Mount the boot partition using label
mount /dev/disk/by-label/COMBAT /mnt/boot

# Activate encrypted swap
swapon /dev/mapper/stella
```

### Step 6: TPM2 enrollment
Enroll the LUKS keys with TPM2 for automatic unlocking:
```bash
# Enroll TPM2 for the SSD (root filesystem) using label
systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/CARTRIDGE

# Enroll TPM2 for the swap partition using label
systemd-cryptenroll --tpm2-device=auto /dev/disk/by-label/STELLA

# Verify enrollment on both devices
systemd-cryptenroll /dev/disk/by-label/CARTRIDGE
systemd-cryptenroll /dev/disk/by-label/STELLA
```

### Step 7: Set up configuration with flakes
```bash
# Generate initial hardware configuration (for reference)
nixos-generate-config --root /mnt

# Copy from USB or existing location
cp -r /path/to/nix/* /mnt/etc/nixos/

# Create secrets directory and copy encrypted secrets (if prepared)
mkdir -p /mnt/etc/nixos/secrets
cp /path/to/secrets/*.age /mnt/etc/nixos/secrets/

# Generate the flake.lock file (pins all dependency versions)
cd /mnt/etc/nixos
nix flake update
```

**Note**: With flakes, you no longer need to manually add channels for home-manager or agenix - they are declared and pinned in `flake.nix`.

### Step 8: Set up agenix in the installer (optional, can be done post-install)
```bash
# If you have secrets to install immediately
nix-shell -p agenix age

# Import your age keys
mkdir -p /mnt/root/.config/age
cp ~/.config/age/keys.txt /mnt/root/.config/age/

# The secrets will be automatically decrypted on first boot
```

### Step 9: Install NixOS
```bash
# Install NixOS using the flake configuration
nixos-install --flake /mnt/etc/nixos#2600AD

# Set root password when prompted
# Set user password
nixos-enter --root /mnt -c 'passwd bittermang'
```

### Step 10: Post-installation setup
After rebooting into the new system:
```bash
# Update hardware configuration with correct UUIDs/labels if needed
sudo nano /etc/nixos/hardware-configuration.nix

# If you haven't set up secrets yet, do it now:
# Generate age keys for the user
sudo -u bittermang mkdir -p /home/bittermang/.config/age
sudo -u bittermang age-keygen -o /home/bittermang/.config/age/keys.txt

# Set up GPG and SSH keys (refer to key generation section above)

# Rebuild system using flake (if changes were made)
sudo nixos-rebuild switch --flake /etc/nixos#2600AD

# Update all flake inputs to latest versions
cd /etc/nixos && sudo nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#2600AD

# Test hibernation (optional)
systemctl hibernate
```

## Configuration File Recap

### Important settings from working config:
- AMD GPU acceleration and AMDVLK driver support
- Zen kernel for gaming performance
- Steam with Gamescope integration
- PipeWire audio configuration
- Essential system packages and fonts
- Firewall and SSH settings
- TPM2 and hardware security features

## Role-Based User and Package Management

The system uses a custom NixOS module (`users.nix`) for role-based package management, inspired by Home Manager's approach. Users are configured via `roles.users.<name>` options, and each user is assigned to package groups.

### Module Options

```nix
# In configuration.nix
roles.users.<name> = {
  enable = true;              # Default: true
  description = "User Name";  # Display name
  uid = 1000;                 # Optional: specific UID
  shell = pkgs.zsh;           # Login shell (default: zsh)
  
  groups = [ ... ];           # Package groups (see below)
  extraGroups = [ ... ];      # Unix groups (wheel, audio, etc.)
  extraPackages = [ ... ];    # Additional packages
  
  isGuest = false;            # Enable tmpfs home (clean room)
  guestTmpfsSize = "2G";      # Size for guest tmpfs
};

# Custom package groups (optional - defaults provided)
roles.packageGroups = {
  my-group = with pkgs; [ package1 package2 ];
};

# Access helper functions
roles.lib.packagesForGroups [ "group1" "group2" ]  # Returns package list
roles.lib.availableGroups                           # List of group names
```

### Available Package Groups

| Group | Description | Key Packages |
|-------|-------------|--------------|
| `developers` | Development tools | git, gh, neovim, gcc, python3, rustup, nodejs, ripgrep, fd |
| `sysadmin` | System administration | htop, btop, ncdu, duf, nmap, rsync, tmux, android-tools |
| `gaming` | Gaming packages | steam, steamcmd, steam-tui, minigalaxy, itch, heroic, mangohud, retroarch |
| `images-viewing` | Image viewers | loupe, gthumb |
| `images-editing` | Image editing | gimp, inkscape, krita, darktable, imagemagick |
| `music-listening` | Music players | spotify, rhythmbox, playerctl |
| `music-production` | DAWs & synths | ardour, lmms, surge-XT, vital, calf, lsp-plugins |
| `music-mixing` | Audio mixing | carla, easyeffects, helvum, qpwgraph |
| `music-management` | Music library | musicbrainz-picard, easytag, soundconverter |
| `video-viewing` | Video players | mpv, vlc, celluloid |
| `video-production` | Video creation | obs-studio (with wlrobs, pipewire plugins) |
| `video-editing` | Video editing | kdenlive, shotcut, handbrake, ffmpeg |
| `web` | Web browsers | firefox, chromium |
| `communication` | Chat/messaging | discord, element-desktop, signal-desktop |
| `office` | Office apps | onlyoffice-bin, obsidian, zathura |
| `desktop` | Desktop utilities | kitty, pcmanfm, rofi-wayland, waybar, dunst, hyprpaper, pavucontrol |

### Current Users

**bittermang** (uid 1000): Primary user with full access to all package groups. Uses Home Manager for additional configuration (Hyprland, VS Code, SSH, Git).

**guest** (uid 1001): Minimal user for clean-room sessions with viewing-only packages. Features:
- tmpfs home directory (`/home/guest`) - wiped on each reboot
- No persistent storage
- Automatic skeleton setup on boot
- Groups: `desktop`, `web`, `images-viewing`, `video-viewing`, `music-listening`, `gaming`

### Adding New Users

Add to `configuration.nix`:

```nix
roles.users.alice = {
  description = "Alice";
  uid = 1002;
  groups = [ "developers" "sysadmin" "desktop" ];
  extraGroups = [ "wheel" "audio" "video" ];
};
```

### Adding Custom Package Groups

Override or extend `roles.packageGroups`:

```nix
roles.packageGroups = config.roles.packageGroups // {
  my-custom-group = with pkgs; [
    package1
    package2
  ];
};
```

Or in the module file (`users.nix`), add to `defaultPackageGroups`.

## Troubleshooting

### If ZFS import fails during boot:
1. Boot from USB installer
2. Decrypt the LUKS container: `cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt`
3. Import the pool manually: `zpool import -f cartridge`
4. Check pool status: `zpool status`
5. Mount and `nixos-enter` to fix configuration

### If TPM2 unlock fails:
1. Boot will prompt for LUKS passphrase
2. After boot, re-enroll TPM2:
   - For SSD: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-label/CARTRIDGE`
   - For swap: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-label/STELLA`

### If hibernation doesn't work:
1. Verify swap is active: `swapon --show`
2. Check resume device in configuration matches `/dev/mapper/stella`
3. Test with `systemctl hibernate`

## Documentation Verification Summary

This configuration was verified against official documentation as of January 2026:

| Component | Version | Verified Items |
|-----------|---------|----------------|
| NixOS | 25.11 (unstable) | Installation steps, ZFS on LUKS setup, systemd-boot |
| Home Manager | unstable | Flake input, stateVersion (25.11), NixOS module integration |
| agenix | main branch | Flake input, separate secrets.nix rules file vs NixOS module config |

### Key corrections made from verification:
- `home.stateVersion` set to "25.11" for fresh installation
- `system.stateVersion` set to "25.11" for fresh installation
- `fonts.fonts` changed to `fonts.packages` (deprecated option)
- `networking.hostId` set to `ad42069f` (required for ZFS)
- Added LUKS device configuration in hardware-configuration.nix
- Added `/nix` ZFS dataset mount
- **Migrated to flakes** - replaced channel-based setup with `flake.nix`
- Removed `networkmanager` group (using systemd-networkd)
- Added `programs.zsh.enable = true` for user shell
- ZFS datasets use `mountpoint=legacy` for proper NixOS integration
- Removed `system.copySystemConfiguration` (incompatible with flakes)
