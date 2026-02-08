# HALLway Changelog

All notable changes to the HALLway project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **ZFS Hibernation Support**: `boot.zfs.allowHibernation = true` with `forceImportRoot = false` for safe hibernate-to-swap
- **GNOME/GDM Display Manager**: Added as alternative display manager alongside Hyprland
- **systemd-networkd**: Switched to `networking.useNetworkd = true` for modern network management
- **Direnv Integration**: `programs.direnv` with `nix-direnv` in Home Manager for automatic flake shell activation
- **Hardware Kernel Modules**: Added AHCI, audio (`snd_hda_intel`, `snd_acp_pci`, `snd_hda_codec`, `snd_hda_codec_hdmi`), I2C (`i2c_amd_mp2_pci`), USB storage, SD card, and CCP modules
- **Swap Tuning**: `vm.swappiness = 100` kernel parameter and swap priority 100 for aggressive hibernation support
- **Hardware Verification Guide**: Post-install verification steps in `hosts/2600AD/INSTALLATION.md` (swap, audio, GPU, kernel errors)
- **New Packages**: `desktop-file-utils` (core), `pciutils` (developers), `dosbox` (gaming), `gparted-full` (sysadmin), `direnv`/`nix-direnv`/`nixd`/`nixfmt` (developers)
- **Colored Task Logging**: VS Code tasks use `script -qec` to preserve ANSI color in terminal while writing timestamped logs to `logs/`

### Changed
- **VS Code Tasks Modernized**: Removed installer-era tasks (`🚀 Install`, `🛠️ Build ZFS`, `🔥🗑️ GC Now`); promoted `⚡ Switch` to default build, added `🛠️ Build` for standard `nix build`. All commands now use direct nix calls (no `nix-shell --run` wrappers)
- **All Role Groups Enabled**: `gaming`, `editors`, `producers`, `gamedev`, `sysadmin` groups now active for bittermang
- **Copilot Instructions**: Updated `.github/copilot-instructions.md` with guest user docs, full VS Code task listing, corrected references
- **Boot Resume Device**: Fixed `resumeDevice` path from `stella` to `stella_crypt` (correct dm-crypt mapping)
- **Hardware Config Cleanup**: Removed deprecated fallback ext4 mount config and `networking.useDHCP` override

### Workarounds
- **ffmpeg-full Build Failure (GCC 15)**: Temporarily commented out `handbrake`, `kdePackages.kdenlive`, and `ffmpeg` from `producers` group — custom vendored ffmpeg in these packages fails to compile with GCC 15 on nixpkgs-unstable (NixOS/nixpkgs#484121, #486277). Standard `ffmpeg` (non-full) builds fine; will re-enable when fix propagates from trunk

---

## [0.0.1] - 2026-01-31 (Codename: 2600AD)

### 🎮 Initial Release

The first HALLway implementation, targeting the Atari VCS 800 as a gaming/media workstation.

### Added

#### Core Infrastructure
- **Flake-based NixOS configuration** for reproducible builds
- **HALLway exported as NixOS module** (`nixosModules.roles`) for other flakes to import
- **ZFS on LUKS** with TPM2 auto-unlock for secure, modern storage
- **Zen kernel** optimized for gaming workloads
- **systemd-networkd** for network management
- **PipeWire** audio with full Bluetooth support

#### Role-Based User Management (`userRoles.nix`)
- Custom NixOS module with `options`/`config` pattern
- **17 package groups** organized by function:
  - System: `developers`, `sysadmin`
  - Gaming: `gaming`
  - Images: `images-viewing`, `images-editing`
  - Music: `music-listening`, `music-production`, `music-mixing`, `music-management`
  - Video: `video-viewing`, `video-production`, `video-editing`
  - Productivity: `web`, `communication`, `office`
  - Desktop: `desktop`
- **Declarative user definitions** via `roles.users.<name>`
- **Guest user support** with tmpfs home directory (clean room)
- **Helper functions** exposed via `roles.lib`

#### Home Manager Integration
- **Clean separation of concerns**:
  - `roles.users` → Package installation
  - Home Manager → Program configuration (dotfiles, settings)
- **Works with or without Home Manager**
- No package duplication between systems

#### Desktop Environment
- **Hyprland compositor** configured for 1368x768@59.85Hz
- **Waybar**, **rofi-wayland**, **dunst** integration
- **Polkit** authentication agent

#### Secrets Management
- **agenix integration** for SSH keys, GPG keys, tokens
- Separation of agenix rules file vs NixOS module

#### Hardware Support
- **AMD GPU** with AMDVLK drivers and ROCm
- Early KMS for console graphics
- Atari VCS 800 specific hardware configuration

#### Documentation
- Comprehensive installation guide (10-step process)
- Disk layout documentation (eMMC + SSD)
- TPM2 enrollment instructions
- Troubleshooting guide

### Users
- **bittermang** (uid 1000): Primary user, full access to all groups
- **guest** (uid 1001): Ephemeral clean-room session

---

## Roadmap

### [0.0.2] - Planned
- [ ] Modularize hardware configuration for multi-machine support
- [ ] Add `roles.presets` for common user archetypes (gamer, developer, artist)
- [ ] Implement `roles.services` for per-user service management
- [ ] Add system backup/restore via ZFS snapshots

### [0.1.0] - Future
- [ ] Abstract HALLway into a standalone flake input
- [ ] Support for multiple machines with shared configuration
- [ ] Web UI for role/user management
- [ ] Integration with Home Manager for seamless user environments

---

## Philosophy

HALLway is built on these principles:

1. **Declarative over Imperative**: Everything is defined in code
2. **Roles over Permissions**: Users are defined by what they *do*, not just what they *can access*
3. **Reproducible by Default**: Any HALLway system can be rebuilt identically
4. **Clean Room Ready**: Guest sessions leave no trace
5. **Self-Documenting**: The configuration *is* the documentation

---

## Links

- **GitHub**: [github.com/markusbittermang/hallway](https://github.com/markusbittermang/hallway)
- **NixOS**: [nixos.org](https://nixos.org)
- **Home Manager**: [github.com/nix-community/home-manager](https://github.com/nix-community/home-manager)
