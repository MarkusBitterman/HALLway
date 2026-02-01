# HALLway Changelog

All notable changes to the HALLway project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **VS Code Integration**: Comprehensive tasks, launch configs, and settings
  - Build System task (Ctrl+Shift+B) - One-click NixOS build
  - Check Install Progress task - Monitor `install-history.log`
  - List Available Packages task - Query role groups via `nix eval`
  - Git workflow tasks (status, stage all)
  - Enhanced `.vscode/settings.json` with file exclusions
- **GNOME & Plasma App Groups**: Fine-grained DE package control
  - `gnome-core`, `gnome-utils`, `gnome-media`, `gnome-productivity`
  - `plasma-core`, `plasma-utils`, `plasma-media`, `plasma-productivity`, `plasma-network`
  - Mix-and-match DE apps without full environment bloat
- **shell.nix**: Development environment for git, gh, nixd, nixfmt, agenix
- **Install Logging**: Versioned `install-history.log` with timestamps
- **README Documentation**: 
  - Three-line philosophy: `groups` (software), `extraGroups` (hardware), `extraPackages` (personal)
  - Usage examples with and without Home Manager
  - Methods for excluding unwanted apps

### Changed
- **Kernel**: `linuxPackages_zen` → `linuxPackages` (stable 6.12.67) for ZFS compatibility
- **Package Management**: VSCode moved to `developers` group (system-installed, Home Manager configures)
- **`.gitignore`**: Added `*.log` and `install-history.log` exclusions

### Fixed
- **ZFS Kernel Compatibility**: Resolved broken package error with 6.18.x kernels
- **VSCode Conflict**: Removed Home Manager package installation to avoid buildEnv collision
- **LUKS Device Mappings**: Corrected `cryptswap`→`stella`, `cryptroot`→`cartridge_crypt`
- **Boot Partition Label**: Changed `BOOT`→`COMBAT` to match actual eMMC label
- **Package Renames**: Updated `rofi-wayland`→`rofi`, `musicbrainz-picard`→`picard`, etc.
- **Hardware Config**: Removed deprecated `amdvlk` driver (RADV is default)
- **XDG Portals**: Added `environment.pathsToLink` for Home Manager portal support

### Security
- **agenix Module**: Temporarily disabled for initial install (to be re-enabled post-boot)

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
