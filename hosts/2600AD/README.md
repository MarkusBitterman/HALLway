# 2600AD

> HALLway host — Atari VCS 800 gaming/media workstation

**Version**: 0.0.1
**Architecture**: x86_64

---

## Hardware

| Component | Detail |
|-----------|--------|
| Board | Atari VCS 800 |
| CPU/GPU | AMD Ryzen R1606G APU (Radeon RX Vega 3, RADV) |
| Boot | eMMC `mmcblk0` — p1 (COMBAT, 2GB FAT32 EFI), p2 (STELLA, ~27GB LUKS swap) |
| Root | SSD `sda` — 1TB, LUKS2 labeled CARTRIDGE → ZFS pool `cartridge` |
| ZFS datasets | `cartridge/root`, `cartridge/home`, `cartridge/nix` |

## Role

Personal workstation. Primary use: development, gaming, media production.

## Configuration Model

- System config: [configuration.nix](configuration.nix)
- agenix secret mappings: [secrets.nix](secrets.nix)
- User environment (Home Manager): [home/bittermang.nix](home/bittermang.nix), [home/guest.nix](home/guest.nix)
- Hardware profile: [hardware-configuration.nix](hardware-configuration.nix) (auto-generated, do not edit)

## Key Features

- **ZFS on LUKS** — stable kernel (`pkgs.linuxPackages`) pinned for ZFS module compatibility; optional TPM2 auto-unlock via `systemd-cryptenroll`
- **Hibernation** — encrypted swap on eMMC (`stella_crypt`), `boot.zfs.allowHibernation = true`
- **GNOME/GDM** — current display manager; Hyprland configured in Home Manager and registered as a session via `programs.hyprland.enable = true`
- **Steam + gamescope** — system-level install with Proton, proton-ge-bin, mangohud
- **WireGuard client** — `wg-hallspace` interface, peer: HALLpass.space hub at `10.44.0.2/24`
- **Syncthing client** — routes through HALLpass.space introducer/relay/discovery
- **iwd + systemd-networkd** — WiFi managed by iwd (no NetworkManager); `iwgtk` for tray management of new/unknown networks
- **agenix secrets** — SSH keys, WireGuard key, GPG key, GitHub token, Syncthing GUI password, WiFi PSK

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
| `HALLPASS_SYNCTHING_DEVICE_ID` | `configuration.nix` | `syncthing cli show system` on HALLpass.space after first boot |
| `DISCOVERY_SERVER_ID` | `configuration.nix` | `journalctl -u syncthing-discovery` on HALLpass.space |
| `RELAY_SERVER_ID` | `configuration.nix` | `journalctl -u syncthing.service` on HALLpass.space |
| `PHONE_SYNCTHING_DEVICE_ID` | `configuration.nix` | Syncthing app → Settings → Advanced → Device ID |

See [docs/secrets.md](../../docs/secrets.md) for the full secrets lifecycle.

## Deploy

```bash
# Validate
nix flake check

# Build and activate
sudo nixos-rebuild switch --flake .#2600AD
```

## Install (fresh machine)

See [INSTALLATION.md](INSTALLATION.md) for the full two-stage installation guide (LUKS + ZFS + NixOS install).

## Known Issues

- `nix-ld.libraries` block contains a JetBrains wiki entry intermixed with Wine/Proton libraries — needs cleanup/annotation
- `handbrake`, `kdePackages.kdenlive`, `ffmpeg` commented out pending GCC 15 build fix (NixOS/nixpkgs#484121)
