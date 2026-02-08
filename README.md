# HALLway

> **📖 New to HALLway?** See the [Documentation Map](docs/DOCUMENTATION_MAP.md) to find what you need.

## Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Project Documentation](#project-documentation)
- [Contributing](#contributing)

## Overview

**the HALLway OS** 🌍🫆🏘️👛🔏; `HALLway` is an operating system stack — and a whole way of doing computing — built around one stubborn, calming idea:

> **Your digital life should live on your hardware, under your rules — by default.** 🫱🏼‍🫲🏿🔏🧠

Not "privacy theater." Not paranoia. Just _practical_ **peace of mind**.

- *a modern device OS* 📲🖥️💻 + *router* 🌐🛜 + *digital wallet* 🫆👛 + *local-first "cloud"* 👟🥅 that treats the public internet 🌐 like *what it often is…* 🤮🦠💉😷

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- HALLway targets **NixOS unstable** (currently tracking 25.11) for latest package availability

### Quick Start

```bash
# Clone the repository
git clone https://github.com/MarkusBitterman/HALLway.git
cd HALLway

# Option 1: Enter the development shell (nix-shell)
nix-shell

# Option 2: Enter the development shell (flakes)
nix develop

# Validate the flake
nix flake check

# Build the system (2600AD example)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel
```

### VS Code Integration

HALLway includes comprehensive VS Code integration with pre-configured tasks:

**Quick Tasks** (Ctrl+Shift+P → "Tasks: Run Task"):
- **Build System** (Ctrl+Shift+B) - Build NixOS configuration
- **Nix Flake Check** - Validate flake syntax
- **Nix Format** - Format all .nix files
- **Check Install Progress** - Monitor installation logs
- **List Available Packages** - View all role groups

See [VS Code Tasks Documentation](docs/VSCODE_TASKS.md) for complete task reference.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed setup instructions.

## Project Documentation

> **🗺️ Can't find what you need?** Check the [Documentation Map](docs/DOCUMENTATION_MAP.md) for a complete guide.

- [HALLway Project Bible](HALLway%20Project%20Bible.md) — Comprehensive project vision and details
- [Architecture & File Structure](docs/ARCHITECTURE.md) — Repository organization and how components work together
- [Contributing Guide](CONTRIBUTING.md) — How to contribute to HALLway
- [Committing Guide](COMMITTING.md) — How to commit changes to the repository
- [Development Tools](docs/dev-tools.md) — Tools and workflows for development
- [VS Code Tasks](docs/VSCODE_TASKS.md) — Pre-configured tasks for installation and development
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) — Solutions to common issues

### Host Documentation

- **2600AD** (Atari VCS 800) — First reference implementation (v0.0.1)
  - [Installation Guide](hosts/2600AD/INSTALLATION.md) — Two-stage USB-bridged installation with ZFS on LUKS
  - [Overview](hosts/2600AD/README.md) — Host-specific configuration details

---

## User Management with Role-Based Packages

HALLway uses a **role-based package system** where users inherit packages from assigned groups. Users are defined by *what they DO*, not just what they can access.

### The Three-Line Philosophy

User configuration works on three simple lines:

1. **`groups`** — Assigns **software** to you (package groups like `developers`, `gaming`, `desktop`)
2. **`extraGroups`** — Assigns **hardware** to you (Unix permissions: `audio`, `video`, `wheel`)
3. **`extraPackages`** — Tailors your **specific environment needs** (one-off packages not in groups)

**Example**:
```nix
roles.users.alice = {
  groups = [ "developers" "desktop" ];          # 1. Software capabilities
  extraGroups = [ "wheel" "audio" "video" ];    # 2. Hardware/system access
  extraPackages = with pkgs; [ blender ];       # 3. Personal tools
};
```

This keeps configuration simple, explicit, and avoids DE/app bloat by design.

### Core Concepts

- **Package Groups**: Collections of related packages (e.g., `developers`, `gaming`, `desktop`)
- **User Roles**: Users assigned to groups inherit all packages from those groups
- **Per-User Packages**: Assigned at system level via `users.users.<name>.packages`
- **Home Manager Integration**: Optional per-user configuration (dotfiles, services, settings)
- **Separation**: `groups` installs software, Home Manager configures it

### Available Package Groups

#### Essentials
- `core` — CLI tools everyone gets (git, curl, htop, gnupg, compression tools)
- `developers` — Programming tools (neovim, vscode, gh, rustup, python, nodejs)
- `sysadmin` — System admin (iotop, tcpdump, nmap, ncdu)

#### Desktop Environment
- `desktop` — Hyprland/Wayland essentials (kitty, rofi, waybar, dunst, pcmanfm)

#### Media (Lightweight → Heavy)
- `viewers` — Media consumption (mpv, vlc, spotify, loupe, zathura) — *lightweight*
- `editors` — Image/audio editing (gimp, inkscape, krita, picard) — *medium*
- `producers` — A/V production (obs, kdenlive, handbrake, ffmpeg, ardour) — *⚠️ heavy builds*

#### Gaming & Creative
- `gaming` — Steam, Heroic, RetroArch, GameMode, MangoHUD
- `gamedev` — Game development (Unity Hub, Blender)

#### Communication
- `communication` — Web, chat, office (firefox, chromium, discord, signal, obsidian)

### Basic Usage (System-Level Only)

Define users in your host's `configuration.nix`:

```nix
{
  roles.users.alice = {
    description = "Alice Smith";
    uid = 1000;
    shell = pkgs.bash;

    # System groups (permissions)
    extraGroups = [ "wheel" "audio" "video" ];

    # Package groups (what gets installed)
    groups = [
      "core"
      "developers"
      "desktop"
      "viewers"
    ];

    # Additional packages not in any group
    extraPackages = with pkgs; [
      blender
    ];
  };
}
```

**Result**: Alice gets all packages from `core`, `developers`, `desktop`, and `viewers`, plus Blender.

### With Home Manager Integration

HALLway separates **what** is installed (system) from **how** it's configured (user):

**In `configuration.nix`** (or via roles module):
```nix
{
  roles.users.bob = {
    description = "Bob Johnson";
    uid = 1001;
    extraGroups = [ "wheel" "audio" "video" "gamemode" ];
    groups = [
      "core"
      "gaming"
      "desktop"
      "viewers"
      "producers"  # ⚠️ Heavy: includes ffmpeg, kdenlive
    ];
  };
}
```

**In `home/bob.nix`** (Home Manager config):
```nix
{ config, pkgs, ... }: {
  # Configure programs (packages come from roles)
  programs.git = {
    enable = true;
    userName = "Bob Johnson";
    userEmail = "bob@example.com";
  };

  programs.kitty = {
    enable = true;
    theme = "Dracula";
    font.size = 12;
  };

  # Hyprland keybindings, etc.
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # ... custom settings
    };
  };
}
```

**Philosophy**: Roles module installs the binaries system-wide, Home Manager configures them per-user.

### Excluding Unwanted Apps

#### Method 1: Don't Add the Group

Only assign groups you actually want:

```nix
roles.users.minimalist = {
  groups = [
    "core"           # CLI basics
    "desktop"        # Just the Hyprland essentials
    # Deliberately NOT including heavy groups like producers, gamedev
  ];
};
```

#### Method 2: Custom Package Groups

Override or extend default groups in your host config:

```nix
{
  roles.packageGroups = {
    # Use default groups
    inherit (config.roles.packageGroups)
      core developers sysadmin gaming desktop;

    # Define custom lightweight media group
    my-light-media = with pkgs; [
      mpv vlc         # Video
      loupe           # Images
      # Exclude spotify, rhythmbox, etc.
    ];
  };

  roles.users.charlie = {
    groups = [ "core" "desktop" "my-light-media" ];
  };
}
```

#### Method 3: Filter Packages Programmatically

Use `lib.filter` to exclude specific packages:

```nix
{
  roles.users.picky = {
    groups = [ "viewers" ];
    extraPackages =
      let
        viewerPackages = config.roles.lib.packagesForGroups [ "viewers" ];
        unwanted = with pkgs; [ spotify rhythmbox ];  # No music apps
      in
        lib.filter (pkg: !(lib.elem pkg unwanted)) viewerPackages;
  };
}
```

### Guest Users (Ephemeral)

Guest accounts with tmpfs homes that reset on reboot:

```nix
{
  roles.users.guest = {
    description = "Guest User";
    isGuest = true;
    guestTmpfsSize = "2G";

    extraGroups = [ "audio" "video" ];
    groups = [ "core" "desktop" "viewers" ];
  };
}
```

### System Bloat Considerations

**Current Behavior**: All user packages are installed system-wide (in `/nix/store`). This means:
- ✅ Packages are deduplicated (same package shared across users)
- ✅ Atomic updates (all users get same package versions)
- ⚠️ Unused packages take disk space if groups overlap

**Optimization Strategies**:

1. **Start light, add as needed** — Begin with `core`, `desktop`, `viewers`, add `producers` later
2. **Avoid heavy groups during install** — `producers`, `gamedev` pull large dependencies (ffmpeg)
3. **Per-host package groups** — Define different groups for different machines

For a single-user system, bloat is minimal. For multi-user systems with diverse needs, careful group assignment keeps the closure size manageable.

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before getting started.

### Quick Links

- [Dev Environment Quickstart](CONTRIBUTING.md#dev-environment-quickstart)
- [Working with Copilot](CONTRIBUTING.md#working-with-copilot)
- [Code Style and Formatting](CONTRIBUTING.md#code-style-and-formatting)
