# HALLway

**the HALLway OS** — an operating system stack built around one idea:

> **Your digital life should live on your hardware, under your rules — by default.**

Not "privacy theater." Not paranoia. Just _practical_ **peace of mind**.

A modern device OS + router + digital wallet + local-first "cloud" that treats the public internet like what it often is.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Standard (Generic)](#standard-generic)
  - [Full Examples by Host](#full-examples-by-host)
- [How to Contribute](#how-to-contribute)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Prerequisites**: [Nix](https://nixos.org/) with flakes enabled

```bash
# Clone the repository
git clone https://github.com/MarkusBitterman/HALLway.git
cd HALLway

# Enter the development shell
nix develop

# Validate the flake
nix flake check

# Build a system (dry run, no activation)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel
```

**VS Code Integration** — HALLway includes pre-configured tasks (Ctrl+Shift+P → "Tasks: Run Task"):

| Task | Shortcut | Description |
|------|----------|-------------|
| ✅ Verify | Ctrl+Shift+T | Validate flake syntax |
| ⚡ Switch | Ctrl+Shift+B | Activate configuration |
| ✨ Format | — | Format all `.nix` files |
| 🛠️ Build | — | Build system closure |

---

## Installation

### Standard (Generic)

HALLway uses a **flake-based NixOS installation** with LUKS encryption, ZFS root filesystem, and sops-nix secrets.

#### Overview

1. **Boot** from NixOS Graphical Installer USB
2. **Partition** disks (EFI boot, encrypted root, optional swap)
3. **Create** LUKS containers and ZFS pool with datasets
4. **Mount** filesystems to `/mnt/<hostname>`
5. **Clone** HALLway flake to `/mnt/<hostname>/etc/nixos`
6. **Create** sops secrets (see below)
7. **Run** `nixos-install --root /mnt/<hostname> --flake .#<hostname>`
8. **Reboot** into your new system

#### Partitioning

You'll need:
- **EFI boot partition** (≥512MB, FAT32)
- **Encrypted root** (LUKS2 → ZFS pool)
- **Encrypted swap** (optional, for hibernation)

#### LUKS + ZFS Setup

```bash
# Create LUKS container
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

#### Mount and Clone

```bash
sudo mkdir -p /mnt/<hostname>/{boot,home,nix}
sudo mount -t zfs <poolname>/root /mnt/<hostname>
sudo mount -t zfs <poolname>/home /mnt/<hostname>/home
sudo mount -t zfs <poolname>/nix /mnt/<hostname>/nix
sudo mount /dev/<boot-partition> /mnt/<hostname>/boot

sudo mkdir -p /mnt/<hostname>/etc/nixos
cd /mnt/<hostname>/etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .
```

#### Create sops Secrets

```bash
nix develop  # Provides sops command

# Create admin age key (first time only)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Edit secrets (decrypts, opens editor, re-encrypts on save)
sops hosts/2600AD/secrets.yaml
```

See [docs/secrets.md](docs/secrets.md) for the full secrets workflow.

#### Install and Reboot

```bash
sudo nixos-install \
  --root /mnt/<hostname> \
  --flake /mnt/<hostname>/etc/nixos#<hostname> \
  --no-root-password

sudo umount -R /mnt/<hostname>
sudo zpool export <poolname>
sudo reboot
```

#### Post-Install

```bash
# Verify ZFS
sudo zpool status

# Rebuild after config changes
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Optional: TPM2 auto-unlock
sudo systemd-cryptenroll --tpm2-device=auto /dev/<luks-device>
```

### Full Examples by Host

For detailed, hardware-specific installation with exact commands:

| Host | Type | Description | Guide |
|------|------|-------------|-------|
| **2600AD** | NixOS | Atari VCS 800 workstation | [hosts/2600AD/README.md](hosts/2600AD/README.md#installation) |
| **HALLpass.space** | NixOS | Minimal VPS (WireGuard hub) | [hosts/HALLpass.space/README.md](hosts/HALLpass.space/README.md#installation) |
| **HelloMoto** | Home Manager | Android phone (Termux + Nix) | [hosts/HelloMoto/README.md](hosts/HelloMoto/README.md) |

---

## How to Contribute

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Dev environment setup
- Code style and formatting guidelines
- Working with Claude Code
- Pull request process

**Quick validation before commits:**

```bash
nix develop
nix flake check
nix fmt
```

---

## Troubleshooting

### "No space left on device" during install

The NixOS installer uses a ~3GB RAM-based tmpfs. Solutions:

1. **Use `nixos-install` directly** — builds to target store, not tmpfs
2. **Run garbage collection**: `sudo nix-collect-garbage -d`
3. **Add swap from a spare USB**: `sudo mkswap /dev/sdX1 && sudo swapon /dev/sdX1`
4. **Avoid `nix build`** — use `nix flake check` for validation instead

### "experimental feature 'flakes' is disabled"

Use the dev shell which enables flakes:

```bash
cd /path/to/HALLway
nix-shell  # or nix develop
nix flake check
```

Or set the environment variable:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### sops: "Failed to get data key"

Your admin key can't decrypt the secrets file. Check:

1. `~/.config/sops/age/keys.txt` exists and contains a valid age private key
2. The key format starts with `AGE-SECRET-KEY-` (no extra `Public key:` line)
3. Your public key is listed in `.sops.yaml`

```bash
# Verify key format
cat ~/.config/sops/age/keys.txt
```

### sops: "no identity matched any of the recipients"

The host key isn't in the recipient list. Rekey the secrets:

```bash
sops updatekeys hosts/<host>/secrets.yaml
```

---

## Project Documentation

- [HALLway Project Bible](HALLway%20Project%20Bible.md) — Comprehensive project vision
- [CLAUDE.md](CLAUDE.md) — AI assistant guidelines and architecture reference
- [docs/secrets.md](docs/secrets.md) — sops-nix secrets management
- [docs/dev-tools.md](docs/dev-tools.md) — Development tools reference

### Related Projects

- [HALLwayDE](https://github.com/MarkusBitterman/HALLwayDE) — Hyprland desktop environment (HyDE port for NixOS); imported as a Home Manager module to manage the complete Wayland desktop stack
