# HALLway Architecture & File Structure 🏗️

This guide explains how the HALLway repository is organized and how the different components work together.

## Table of Contents

- [Repository Overview](#repository-overview)
- [Core Concepts](#core-concepts)
- [File Structure](#file-structure)
- [How It All Works Together](#how-it-all-works-together)
- [Key Technologies](#key-technologies)

---

## Repository Overview

HALLway is built on **NixOS** and uses **Nix flakes** for reproducible, declarative system configuration. The repository structure follows a modular pattern where:

- **Flake** (`flake.nix`) - Entry point defining inputs and outputs
- **Modules** - Reusable NixOS modules (role-based user management)
- **Hosts** - Per-machine configurations (e.g., 2600AD for Atari VCS 800)
- **Documentation** - Guides, references, and troubleshooting

---

## Core Concepts

### 1. Flakes (Nix Flakes)

HALLway uses Nix flakes for dependency management and reproducibility:

```
flake.nix          → Entry point, defines system
flake.lock         → Pinned dependency versions (auto-generated)
```

**Benefits**:
- ✅ Reproducible builds (same inputs → same outputs)
- ✅ No system-wide channels needed
- ✅ Easy dependency updates (`nix flake update`)

### 2. NixOS Modules

HALLway exports reusable NixOS modules that other flakes can import:

```nix
# Other projects can use HALLway modules
inputs.hallway.url = "github:MarkusBitterman/HALLway";

# Then import
imports = [ inputs.hallway.nixosModules.roles ];
```

### 3. Host Configurations

Each physical machine has its own configuration:

```
hosts/2600AD/       → Atari VCS 800 configuration
hosts/<new-host>/   → Future hardware configurations
```

### 4. Separation of Concerns

**System Level** (what's installed):
- Managed by `roles.users.<name>.groups`
- Packages installed system-wide to `/nix/store`

**User Level** (how it's configured):
- Managed by Home Manager (`home/<name>.nix`)
- Per-user dotfiles, settings, preferences

---

## File Structure

```
HALLway/
├── flake.nix                      # 🎯 Entry point - defines all outputs
├── flake.lock                     # 📌 Pinned dependency versions
├── shell.nix                      # 🐚 Legacy dev shell (for nix-shell)
│
├── modules/                       # 🧩 HALLway NixOS modules
│   ├── default.nix               # Default module (reserved for future)
│   └── userRoles.nix             # ⭐ Role-based user management
│
├── hosts/                         # 💻 Per-machine configurations
│   └── 2600AD/                   # Atari VCS 800 (first reference host)
│       ├── configuration.nix     # System configuration (boot, networking, services)
│       ├── hardware-configuration.nix  # Hardware-specific (auto-generated + tweaked)
│       ├── secrets.nix           # agenix secret definitions (NixOS module)
│       ├── secrets/              # Encrypted .age files (excluded from git)
│       ├── home/                 # Home Manager configs
│       │   ├── bittermang.nix   # Primary user config (Hyprland, git, ssh, vscode)
│       │   └── guest.nix         # Guest user config (minimal)
│       ├── INSTALLATION.md       # Host-specific installation guide
│       └── README.md             # Host overview and legacy instructions
│
├── docs/                          # 📚 Documentation
│   ├── dev-tools.md              # Development environment guide
│   ├── TROUBLESHOOTING.md        # Consolidated issue solutions
│   └── VSCODE_TASKS.md           # VS Code task reference
│
├── .vscode/                       # 🛠️ VS Code configuration
│   ├── tasks.json                # Pre-configured tasks (build, install, validate)
│   ├── settings.json             # Workspace settings
│   ├── extensions.json           # Recommended extensions
│   └── launch.json               # Debugger configs (if any)
│
├── .github/                       # 🐙 GitHub-specific files
│   ├── copilot-instructions.md   # Copilot agent instructions
│   └── workflows/                # CI/CD (future)
│
├── README.md                      # 📖 Project overview and user guide
├── INSTALLATION.md                # Generic installation template
├── CONTRIBUTING.md                # Contribution guidelines
├── COMMITTING.md                  # Git workflow guide
├── CHANGELOG.md                   # Release notes and version history
├── HALLway Project Bible.md      # 🎨 Vision document and philosophy
├── LICENSE                        # Project license
├── .gitignore                     # Git exclusions
└── .editorconfig                  # Editor formatting rules
```

---

## How It All Works Together

### 1. Entry Point: `flake.nix`

```nix
# Defines inputs (dependencies)
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = { url = "..."; inputs.nixpkgs.follows = "nixpkgs"; };
  agenix = { url = "..."; inputs.nixpkgs.follows = "nixpkgs"; };
};

# Defines outputs (what this flake provides)
outputs = {
  nixosModules = { roles = ./modules/userRoles.nix; };  # Exported for others
  nixosConfigurations."2600AD" = { ... };                # Host config
  devShells.default = { ... };                           # Dev environment
};
```

### 2. Host Configuration Flow

```
flake.nix
  ↓
nixosConfigurations."2600AD"
  ↓
hosts/2600AD/configuration.nix      ← System settings
  ├── imports modules/userRoles.nix  ← Role system
  ├── imports hardware-configuration.nix
  ├── imports secrets.nix            ← agenix secrets
  ↓
roles.users.bittermang               ← User definition
  ├── groups = [ "developers" "gaming" "desktop" ]  ← Package groups
  ↓
Home Manager
  ↓
hosts/2600AD/home/bittermang.nix    ← User-level config (dotfiles)
```

### 3. Role-Based Package Management

Defined in `modules/userRoles.nix`:

```nix
# Define package groups
defaultPackageGroups = {
  developers = with pkgs; [ git neovim gcc python3 ];
  gaming = with pkgs; [ steam heroic mangohud ];
  desktop = with pkgs; [ kitty rofi waybar ];
};

# Assign to users
roles.users.<name> = {
  groups = [ "developers" "desktop" ];  # Gets packages from both groups
  extraPackages = [ pkgs.blender ];     # Plus individual packages
};
```

**Result**: User inherits all packages from assigned groups + extras.

### 4. Development Workflow

```bash
# 1. Enter dev environment
nix develop  # or nix-shell

# 2. Make changes to configuration

# 3. Validate
nix flake check

# 4. Format
nix fmt

# 5. Test build (on running system)
sudo nixos-rebuild switch --flake .#2600AD

# 6. Commit and push
git add -A
git commit -m "feat: Add something"
git push
```

---

## Key Technologies

### Nix & NixOS

- **Nix**: Purely functional package manager
- **NixOS**: Linux distribution built on Nix
- **Flakes**: Modern Nix feature for dependency management

**Why?**
- Reproducible builds
- Declarative configuration
- Rollback capabilities
- No "dependency hell"

**Learn More**:
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)

---

### Home Manager

User environment management for NixOS.

**Purpose**: Configure per-user settings (dotfiles, programs, services)

**Example**:
```nix
programs.git = {
  enable = true;
  userName = "Alice";
  userEmail = "alice@example.com";
};
```

**Learn More**:
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Wiki](https://nixos.wiki/wiki/Home_Manager)

---

### agenix

Age-encrypted secrets for NixOS.

**Purpose**: Securely store SSH keys, API tokens, passwords

**Files**:
- `secrets/*.age` - Encrypted secret files (not in git)
- `secrets.nix` - Secret definitions (which keys can decrypt)

**Learn More**:
- [agenix GitHub](https://github.com/ryantm/agenix)
- [agenix Wiki](https://nixos.wiki/wiki/Agenix)

---

### ZFS

Advanced filesystem with snapshots, compression, encryption.

**HALLway Uses**:
- Three datasets: `root`, `home`, `nix`
- LZ4 compression for speed
- Legacy mountpoints for NixOS compatibility

**Learn More**:
- [ZFS on NixOS](https://nixos.wiki/wiki/ZFS)

---

### LUKS

Full disk encryption for security.

**HALLway Uses**:
- LUKS2 with labeled devices
- TPM2 auto-unlock support
- Encrypted root and swap

**Learn More**:
- [LUKS on NixOS](https://nixos.wiki/wiki/Full_Disk_Encryption)

---

## Adding a New Host

To add support for new hardware:

1. **Create host directory**:
   ```bash
   mkdir -p hosts/<hostname>
   ```

2. **Generate hardware config**:
   ```bash
   nixos-generate-config --root /mnt/<hostname>
   cp /mnt/<hostname>/etc/nixos/hardware-configuration.nix hosts/<hostname>/
   ```

3. **Create configuration.nix**:
   ```nix
   # hosts/<hostname>/configuration.nix
   { config, pkgs, ... }: {
     imports = [
       ./hardware-configuration.nix
       # Add more as needed
     ];
     
     networking.hostName = "<hostname>";
     # ... system config
     
     roles.users.<user> = {
       groups = [ "developers" "desktop" ];
     };
   }
   ```

4. **Create Home Manager config**:
   ```bash
   mkdir -p hosts/<hostname>/home
   # Create hosts/<hostname>/home/<user>.nix
   ```

5. **Register in flake.nix**:
   ```nix
   nixosConfigurations."<hostname>" = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [
       hallwayModules.roles
       ./hosts/<hostname>/configuration.nix
       # Home Manager integration
       # ...
     ];
   };
   ```

6. **Document**:
   - Create `hosts/<hostname>/INSTALLATION.md`
   - Create `hosts/<hostname>/README.md`

---

## Module Extension

To add custom package groups:

```nix
# In your host's configuration.nix
roles.packageGroups = config.roles.packageGroups // {
  my-custom-group = with pkgs; [
    package1
    package2
  ];
};

roles.users.alice = {
  groups = [ "my-custom-group" ];
};
```

To extend the roles module itself, edit `modules/userRoles.nix`.

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [INSTALLATION.md](../INSTALLATION.md) - Generic installation guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development guidelines
- [Development Tools](dev-tools.md) - Dev environment setup
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

---

**Last Updated**: 2026-02-01
