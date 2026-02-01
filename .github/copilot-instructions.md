# HALLway AI Agent Instructions

## Project Overview

HALLway is a NixOS-based operating system focused on **local-first computing** with security by default. Think: personal device OS + router + digital wallet that treats the public internet as untrusted infrastructure. Currently at v0.0.1 with first reference host `2600AD` (Atari VCS 800).

## Architecture & Key Components

### Flake Structure (`flake.nix`)
- **Core pattern**: `nixosModules` expose reusable HALLway modules, `nixosConfigurations` define per-host systems
- **Inputs**: `nixpkgs`, `home-manager` (user environment), `agenix` (secrets management)
- **Outputs**:
  - `nixosModules.roles` → `modules/userRoles.nix` (role-based package management)
  - `nixosConfigurations."2600AD"` → `hosts/2600AD/configuration.nix` (host config)
  - `devShells.default` → development environment with `nixd`, `nixfmt-rfc-style`

### Module System (`modules/`)
- `userRoles.nix`: Role-based user management module defining package groups (e.g., `developers`, `gaming`, `desktop`)
- **Philosophy**: Users defined by what they DO (roles), not just what they can ACCESS
- Usage example:
  ```nix
  roles.users.bittermang = {
    groups = [ "developers" "gaming" "desktop" ];
    extraPackages = [ pkgs.blender ];
  };
  ```

### Host Configuration (`hosts/2600AD/`)
- `configuration.nix`: System-level config (boot, networking, services, users via roles)
- `hardware-configuration.nix`: Hardware detection (auto-generated)
- `secrets.nix`: agenix secrets (SSH keys, tokens) - encrypted `.age` files in `secrets/`
- `home/bittermang.nix`: Home Manager config for USER ENVIRONMENT (dotfiles, Hyprland WM settings)

**Separation of Concerns**:
- `roles.users.<name>.groups` → What packages are installed (system-level)
- `home/<name>.nix` → How those packages are configured (user-level)

### Installation Model
Two-stage USB-bridged installation (see `hosts/2600AD/INSTALLATION.md`):
1. Boot from USB installer (has ZFS kernel modules)
2. Install to LUKS-encrypted SSD with ZFS datasets (`cartridge/root`, `cartridge/home`, `cartridge/nix`)
3. Uses `nixos-install --flake github:MarkusBitterman/HALLway#2600AD`

## Development Workflows

### Essential Commands
```bash
nix develop              # Enter dev shell (auto-loads tools)
nix flake check          # Validate flake syntax (TEST task)
nix fmt                  # Format all .nix files (nixfmt-rfc-style, RFC 166)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel  # Build system
```

### VS Code Tasks
- **Nix Flake Check** (Ctrl+Shift+P → Run Task) - validates flake, runs by default
- **Nix Format** - formats with `nixfmt-rfc-style`

### Testing Changes
```bash
# On the 2600AD host, rebuild and switch:
sudo nixos-rebuild switch --flake .#2600AD
```

## Code Conventions

### Nix Formatting
- **Style**: `nixfmt-rfc-style` (RFC 166) - enforced by `nix fmt`
- **Header blocks**: ASCII box art with project name, file purpose, URL
  ```nix
  # ╔═══════════════════════════════════════════════════════════════════════════╗
  # ║  HALLway                                                                  ║
  # ║  modules/userRoles.nix - Role-Based User Management Module                ║
  # ╚═══════════════════════════════════════════════════════════════════════════╝
  ```
- **Section dividers**: Use `# ═══════` for major sections, `# ─────────` for subsections

### Commit Messages
Semantic format from `COMMITTING.md`:
```
<type>: <description>

Types: feat, fix, docs, refactor, chore, v0.x.x
Examples:
  v0.0.1: 2600AD - Atari VCS 800 initial working build
  feat: Add TPM2 auto-unlock support for LUKS partitions
```

### Secrets Management
- **Never commit plaintext secrets** - use agenix (`.age` encrypted files)
- Store in `hosts/<hostname>/secrets/` (excluded from git)
- Reference in `secrets.nix` with owner/group/mode
- Example: `age.secrets."ssh_key_github".file = ./secrets/ssh_key_github.age;`

## Project-Specific Patterns

### Adding New Hosts
1. Create `hosts/<hostname>/` directory
2. Add `configuration.nix` (import `hallwayModules.roles`)
3. Add hardware-configuration.nix (run `nixos-generate-config`)
4. Add `home/<username>.nix` for Home Manager
5. Register in `flake.nix` under `nixosConfigurations.<hostname>`

### Extending Role System
To add new package groups, edit `modules/userRoles.nix`:
```nix
defaultPackageGroups = {
  my-new-role = with pkgs; [ package1 package2 ];
};
```

Then assign to users in host `configuration.nix`:
```nix
roles.users.myuser.groups = [ "my-new-role" ];
```

### Home Manager Integration
- Installed per-host via `home-manager.nixosModules.home-manager` in flake
- User configs: `home-manager.users.<name> = import ./hosts/<host>/home/<name>.nix;`
- Do NOT install packages here - only configure them (packages come from `roles.users`)

## Philosophy & Design Intent

From `HALLway Project Bible.md`:
- **Local-first**: Your hardware, your rules (not "cloud" = someone else's computer)
- **Trust tiers**: Relationships not flat networks (pro → acquaintance → friend → family)
- **Pool-based networking**: IPv6 address pools encode identity and policy
- **Handshake-based access**: Explicit consent via "digital flags" (WireGuard keys in steganographic images)
- **Reproducibility via Nix**: "Works on my machine" is a bug, not a feature

## AI Tool Usage Guidelines

From `CONTRIBUTING.md`:
- ✅ Use Copilot for drafting boilerplate, configs, documentation
- ✅ Always review and test suggestions (`nix flake check` after changes)
- 🚫 Never include secrets, tokens, or credentials in prompts
- 🚫 Don't blindly accept - verify cryptographic code, network config, permissions

### File Editing Discipline
- **NEVER clobber files** - always use targeted edits (`replace_string_in_file`) rather than full file replacements
- **Read before writing** - understand what's in a file before modifying it
- **Preserve structure** - maintain existing formatting, comments, and organization
- **Two scopes exist**:
  1. **Generic HALLway** (`/INSTALLATION.md`, `/README.md`) - for anyone using the flake
  2. **Host-specific** (`hosts/<hostname>/INSTALLATION.md`) - for that exact hardware setup
- **Don't delete to replace** - if restructuring, migrate content incrementally

## Quick Reference

**Key Files**:
- `flake.nix` - Entry point, defines all outputs
- `modules/userRoles.nix` - Role-based package groups (416 lines, read for full context)
- `hosts/2600AD/configuration.nix` - First reference host
- `CONTRIBUTING.md` - Development workflows
- `HALLway Project Bible.md` - Vision and philosophy

**External Dependencies**:
- NixOS/nixpkgs (unstable channel)
- home-manager (user environment management)
- agenix (secrets encryption)
- ZFS (filesystem, requires kernel module match during install)

**Current State**: v0.0.1 - Single working host (2600AD), foundation for multi-device HALLway ecosystem.
