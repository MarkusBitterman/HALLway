# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix develop              # Enter dev shell (sets RULES, EDITOR, loads agenix wrapper)
nix flake check          # Validate flake syntax — primary test command (Ctrl+Shift+T in VS Code)
nix fmt                  # Format all .nix files with nixfmt (RFC 166)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel  # Build without activating
sudo nixos-rebuild switch --flake .#2600AD          # Build and activate on 2600AD
sudo nixos-rebuild switch --flake .#HALLpass.space  # Build and activate on VPS (run on VPS)
agenix -e <file.age> -i ~/.ssh/id_hallpass          # Edit an encrypted secret
agenix -r -i ~/.ssh/id_hallpass                     # Rekey all secrets (after recipient changes)
```

Always run `nix flake check` and `nix fmt` before committing.

## Architecture

### Flake (`flake.nix`)
Entry point. Defines `nixosConfigurations` (NixOS hosts), `homeConfigurations` (non-NixOS hosts), and `devShells.default`. `nixosModules.default` is exported but contains no active modules — host configs compose Home Manager and agenix directly. `modules/userRoles.nix` exists but is **not imported anywhere** (dead code from a removed design; candidate for deletion).

**Inputs**: `nixpkgs` (unstable), `home-manager`, `agenix`, `flake-utils`

### Hosts (`hosts/`)
NixOS hosts contain:
- `configuration.nix` — system-level: boot, networking, services, `users.users`
- `hardware-configuration.nix` — auto-generated, do not edit manually
- `secrets.nix` — agenix module: runtime paths, owners, modes for deployed secrets
- `home/<user>.nix` — Home Manager: package installation **and** user-space configuration

Non-NixOS hosts (standalone Home Manager) contain only:
- `home/<user>.nix` — Home Manager config; also imports `../secrets.nix`
- `secrets.nix` — agenix homeManagerModule config; identity is user SSH key, not system host key

**Current hosts**:
- `2600AD` — Atari VCS 800; workstation/gaming node; ZFS on LUKS, GNOME (transitioning to Hyprland), WireGuard client, Syncthing client; activated with `sudo nixos-rebuild switch --flake .#2600AD`
- `HALLpass.space` — Minimal VPS; WireGuard hub + Syncthing introducer/relay/discovery; nginx front; **not yet deployed** (contains placeholder values); activated with `sudo nixos-rebuild switch --flake .#HALLpass.space`
- `HelloMoto` — Android phone (Termux + Nix, `aarch64-linux`); standalone Home Manager only; WireGuard and Syncthing via Android apps; activated with `home-manager switch --flake .#HelloMoto`

### User Model
`users.users.<name>` in `configuration.nix` defines the account and group membership. Home Manager (`hosts/<host>/home/<user>.nix`) handles both package installation (`home.packages`) and dotfile/app configuration. There is no roles module in use.

Guest user on 2600AD has an ephemeral tmpfs `/home/guest` (wiped on reboot); its packages are defined directly on `users.users.guest.packages` in `configuration.nix` since Home Manager persistence is pointless for a guest.

### Networking (2600AD)
2600AD uses `networking.useNetworkd = true` with iwd for WiFi. NetworkManager is explicitly disabled (`networking.networkmanager.enable = false`). WiFi PSK is an agenix secret deployed to `/var/lib/iwd/<SSID>.psk` — the SSID placeholder in `hosts/2600AD/secrets.nix` must be replaced with the real network name before deploying.

### Secrets (agenix)
Two completely different files share the name `secrets.nix`:

| File | Purpose | Used by |
|------|---------|---------|
| `secrets.nix` (repo root) | agenix CLI rules — maps `.age` files to recipient age public keys | `agenix -e` / `agenix -r` |
| `hosts/<host>/secrets.nix` | NixOS module — declares runtime paths, owners, modes | `nixos-rebuild switch` |

Encrypted `.age` files live in `hosts/<host>/secrets/` and are committed to git. The admin SSH key is `~/.ssh/id_hallpass` — **always pass `-i ~/.ssh/id_hallpass`** to agenix. The dev shell sets `RULES="$PWD/secrets.nix"` automatically.

**Critical pitfall**: `nixpkgs` ships `agenix-cli` (Rust rewrite, incompatible). The dev shell provides the correct `ryantm/agenix` wrapper. If `agenix --version` shows `agenix-cli`, exit and re-enter the dev shell.

**Creating a new secret**: the `.age` file must not exist before first encryption — delete it if present, then run `agenix -e`.

Secrets are referenced in NixOS config via `config.age.secrets."<name>".path`, in NixOS-backed Home Manager via `osConfig.age.secrets."<name>".path`, and in standalone Home Manager (HelloMoto) via `config.age.secrets."<name>".path` directly.

**Current gap**: HALLpass.space secrets are encrypted for the admin key only — the VPS host key is not yet known. After first VPS boot: get host key with `ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age`, fill in `secrets.nix`, then run `agenix -r -i ~/.ssh/id_hallpass`.

### Version Control
Currently Git with GitHub as origin. **Plan**: migrate primary VCS to Mercurial (Hg), self-hosted at `hg.hallpass.space` (once HALLpass.space is deployed). GitHub will become a read-only mirror. Copilot has been replaced by Claude Code.

## Code Conventions

### Nix Formatting
Use `nixfmt` (RFC 166) via `nix fmt`. File headers use ASCII box art:
```nix
# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  path/to/file.nix - Purpose                                               ║
# ╚════════════════╝
```
Section dividers: `# ═══════` for major sections, `# ─────────` for subsections.

### Commit Messages
```
<type>: <description>

Types: feat, fix, docs, refactor, chore, v0.x.x
```
Examples: `feat: Add TPM2 auto-unlock support`, `v0.0.1: 2600AD initial working build`

### Adding a New Host
1. Create `hosts/<hostname>/` with `configuration.nix`, `hardware-configuration.nix`, `secrets.nix`, `home/<user>.nix`
2. Register in `flake.nix` under `nixosConfigurations.<hostname>`
3. Add recipient age keys to root `secrets.nix` and create secrets with `agenix -e`

### Placeholder Values
Several config values in `hosts/HALLpass.space/configuration.nix` and `hosts/2600AD/configuration.nix` are not yet populated — they are literal placeholder strings that must be replaced before deployment is functional:
- `HALLPASS_WG_PUBLIC_KEY` / `DESKTOP_WG_PUBLIC_KEY` / `PHONE_WG_PUBLIC_KEY` — WireGuard public keys
- `HALLPASS_SYNCTHING_DEVICE_ID` / `PHONE_SYNCTHING_DEVICE_ID` — Syncthing device IDs
- `DISCOVERY_SERVER_ID` / `RELAY_SERVER_ID` — Syncthing infra IDs from HALLpass.space startup logs

See `docs/secrets.md` for the full workflow on deriving and filling these in.
