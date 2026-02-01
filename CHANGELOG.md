# HALLway Changelog

All notable changes to the HALLway project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
