# HALLway Changelog

All notable changes to the HALLway project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Changed

- **NixOS 26.05 compatibility**: Fixed deprecation warnings across all hosts
  - `security.acme.defaults.credentialsFile` → `environmentFile` (HALLpass.space)
  - `programs.ssh.matchBlocks` → `programs.ssh.settings` (all hosts)
  - `wineWowPackages` → `wineWow64Packages` (2600AD)
  - `surge-XT` → `surge-xt` (2600AD)
  - `boot.zfs.allowHibernation` commented out pending `unsafeAllowHibernation` migration (2600AD)
- **DOORwayDE deduplication** (2600AD): Removed 15 packages from `bittermang.nix` now provided by DOORwayDE module (hyprland, hyprlock, hypridle, hyprpaper, hyprsunset, waybar, rofi, dunst, wlogout, kitty, grim, slurp, satty, cliphist, playerctl, awww)
- **Minimal VPS cleanup** (HALLpass.space): Removed `gnupg` (pulls X11 via pinentry), deduplicated `age` and `jq` (already in systemPackages)

### Removed

- **helvum** (2600AD, userRoles.nix): Package removed from nixpkgs (unmaintained, vulnerable dependency); qpwgraph already present as replacement

### Added

- **AdGuard DNS** (2600AD): System-wide DNS using AdGuard public resolvers (94.140.14.14, 94.140.15.15, IPv6 variants)
- **greetd + regreet** (2600AD): Wayland-native display manager replacing GDM; GTK4 greeter with user list, password entry, and session selection; runs on cage minimal compositor
- **UWSM session management** (2600AD): Hyprland now launched via Universal Wayland Session Manager (`programs.hyprland.withUWSM = true`)
- **Gamescope Vulkan fix** (2600AD): Added `debug { full_cm_proto = true }` to Hyprland config for Steam/gamescope compatibility
- **HALLpass.space host**: Second HALLway host — minimal VPS acting as WireGuard hub, Syncthing introducer/relay/discovery, nginx edge, and Mercurial server
- **Mercurial hosting** (`hg.hallpass.space`): `hgweb` systemd service serving repos from `/srv/hg/repos/**`; nginx reverse proxy with ACME TLS
- **Static web** (`hallpass.space`): nginx vhost serving `/srv/hallspace/_public/`; ACME TLS via Let's Encrypt
- **iwd WiFi management** (2600AD): Replaced NetworkManager with `networking.wireless.iwd`; systemd-networkd now manages both ethernet and WiFi; `iwgtk` tray app launched at Hyprland startup
- **`wifi-home` secret** (2600AD): WiFi credentials deployed as an iwd PSK file at `/var/lib/iwd/<SSID>.psk`
- **Hyprland session registration** (2600AD): `programs.hyprland.enable = true` in system config — installs the `.desktop` session file so GDM shows Hyprland as a session option
- **CLAUDE.md**: Project context file for Claude Code AI assistant

### Changed

- **Secrets management**: Migrated from agenix to [sops-nix](https://github.com/Mic92/sops-nix); secrets now stored in `hosts/<host>/secrets.yaml` (encrypted YAML) instead of individual `.age` files; config in `.sops.yaml`; uses dedicated age key at `~/.config/sops/age/keys.txt` for editing and SSH host key for runtime decryption
- **Hibernation** (2600AD): Enabled `boot.zfs.allowHibernation = true` and set `boot.zfs.forceImportRoot = false`; swap on LUKS partition (`/dev/mapper/stella_crypt`) used as resume device
- **WireGuard subnet**: Changed from `10.23.11.x` to `10.23.11.x` (2600AD = `.80`, HALLpass.space = `.1`, HelloMoto = `.64`)
- **Display manager** (2600AD): Replaced GDM/GNOME with greetd + regreet (Wayland-native)
- **Steam configuration** (2600AD): Moved `freetype` from `extraCompatPackages` (wrong) to `extraPackages` (correct); removed redundant `steam`/`steam-run` from `environment.systemPackages`; removed `extest` (X11-only)
- **Hyprland Home Manager** (2600AD): Added `systemd.enable = false` to prevent conflict with UWSM session management
- **ZFS import** (2600AD): Temporarily added `forceImportAll = true` and `forceImportRoot = true` as workaround for hostId changes
- **hostId** (2600AD): Changed to `76fe1b68` (derived from machine-id for consistency)
- **Networking (2600AD)**: Temporarily using NetworkManager while systemd-networkd configuration is stabilized; commented out iwd/networkd config
- **GDM Wayland** (2600AD): `services.displayManager.gdm.wayland = true` — required for Wayland sessions to appear in the GDM session picker
- **Hyprland Home Manager** (2600AD): Added `package = pkgs.hyprland` to pin HM to the same package as the system module; removed redundant `xdg-desktop-portal-hyprland` from `home.packages` and the `xdg.portal` block (both owned by the NixOS module)
- **HALLpass.space system packages**: Added `mercurial`, `age`, `ssh-to-age` for on-server operations
- **HALLpass.space header**: Added HALLway ASCII box art file header to `configuration.nix`
- **AI tooling**: Migrated from GitHub Copilot to Claude Code

### Infrastructure

- `systemd.tmpfiles.rules` creates `/srv/hallspace/_public/` and `/srv/hg/repos/` on HALLpass.space activation
- `recommendedProxySettings = true` added to nginx on HALLpass.space for proper reverse proxy headers

---

## [0.0.1] - 2026-01-31 (Codename: 2600AD)

First HALLway implementation, targeting the Atari VCS 800 as a gaming/media workstation.

### Added

#### Core Infrastructure
- Flake-based NixOS configuration for reproducible builds
- ZFS on LUKS with TPM2 auto-unlock option
- Stable kernel (`pkgs.linuxPackages`) pinned for guaranteed ZFS module compatibility
- systemd-networkd for network management
- PipeWire audio with Bluetooth support
- zram swap with hibernation support (`boot.zfs.allowHibernation = true`)
- GNOME/GDM as display manager (Hyprland targeted for daily use)
- agenix secrets management (SSH keys, WireGuard keys, GPG key, GitHub token, Syncthing GUI password)
- Home Manager for user environment and dotfile management

#### User Configuration
- `bittermang` (uid 1000): primary user; packages and config in `home/bittermang.nix`
- `guest` (uid 1001): ephemeral clean-room session with tmpfs `/home/guest` wiped on reboot
- Guest packages defined directly on `users.users.guest.packages` (HM persistence pointless for tmpfs home)

#### Desktop Environment
- Hyprland compositor config in Home Manager (keybindings, monitor resolution, startup apps)
- Waybar, rofi, dunst, hyprpaper, kitty, pavucontrol, polkit-gnome
- WireGuard client (`wg-hallspace`) connected to HALLpass.space hub at `10.23.11.80/24`
- Syncthing client with HALLpass.space as introducer (pending key population)

#### 2600AD-Specific Hardware
- Atari VCS 800 disk layout: eMMC (`mmcblk0`) for boot + swap, SSD (`sda`) for LUKS/ZFS root
- ZFS pool `cartridge` with datasets: `root`, `home`, `nix`
- AMD GPU (RADV), gamescope + Steam with Proton/proton-ge-bin
- `nix-ld` with Wine/Proton library set for non-NixOS ELF binaries

### Workarounds
- **ffmpeg-full (GCC 15)**: `handbrake`, `kdePackages.kdenlive`, `ffmpeg` commented out — custom vendored ffmpeg in these packages fails to compile with GCC 15 on nixpkgs-unstable (NixOS/nixpkgs#484121, #486277). Standard ffmpeg builds fine; will re-enable when fix propagates.

---

## Roadmap

### [0.0.2] — HALLpass.space live
- [ ] First deploy of HALLpass.space (VPS provision, sops rekey, WireGuard keys, Syncthing IDs)
- [ ] All placeholder values replaced (`894D+6bHWTBC3CXPbtn9Nv/hTnk+vOnd0PrshTPMxQo=`, `DESKTOP_WG_PUBLIC_KEY`, Syncthing device IDs)
- [ ] HALLway migrated from Git to Mercurial; primary repo at `hg.hallpass.space`
- [ ] GitHub becomes a read-only mirror

### [0.1.0] — Multi-device HALLway
- [ ] Phone on WireGuard overlay + Syncthing sync via HALLpass.space
- [ ] `2600AD.hallpass.space` DNS resolving over WireGuard
- [ ] Hyprland as sole desktop (GNOME removed)
- [ ] ZFS snapshot-based system backup

---

## Links

- **Mercurial** (planned): `hg.hallpass.space`
- **GitHub** (mirror): [github.com/markusbittermang/hallway](https://github.com/markusbittermang/hallway)
- **NixOS**: [nixos.org](https://nixos.org)
- **Home Manager**: [github.com/nix-community/home-manager](https://github.com/nix-community/home-manager)
