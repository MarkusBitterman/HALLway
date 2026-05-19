# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix develop              # Enter dev shell (loads sops, age, etc.)
nix flake check          # Validate flake syntax — primary test command (Ctrl+Shift+T in VS Code)
nix fmt                  # Format all .nix files with nixfmt (RFC 166)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel  # Build without activating
sudo nixos-rebuild switch --flake .#2600AD          # Build and activate on 2600AD
sudo nixos-rebuild switch --flake .#HALLpass.space  # Build and activate on VPS (run on VPS)
sops hosts/2600AD/secrets.yaml                      # Edit encrypted secrets (decrypt/edit/re-encrypt)
sops updatekeys hosts/2600AD/secrets.yaml           # Rekey after adding recipients to .sops.yaml
```

Always run `nix flake check` and `nix fmt` before committing.

## Architecture

### Flake (`flake.nix`)
Entry point. Defines `nixosConfigurations` (NixOS hosts), `homeConfigurations` (non-NixOS hosts), and `devShells.default`. `nixosModules.default` is exported but contains no active modules — host configs compose Home Manager and sops-nix directly. `modules/userRoles.nix` exists but is **not imported anywhere** (dead code from a removed design; candidate for deletion).

**Inputs**: `nixpkgs` (unstable), `home-manager`, `sops-nix`, `flake-utils`, `hallwayde`

### Hosts (`hosts/`)
NixOS hosts contain:
- `configuration.nix` — system-level: boot, networking, services, `users.users`
- `hardware-configuration.nix` — auto-generated, do not edit manually
- `secrets.nix` — sops-nix module: runtime paths, owners, modes for deployed secrets
- `home/<user>.nix` — Home Manager: package installation **and** user-space configuration

Non-NixOS hosts (standalone Home Manager) contain only:
- `home/<user>.nix` — Home Manager config; also imports `../secrets.nix`
- `secrets.nix` — sops-nix homeManagerModule config; identity is user SSH key, not system host key

**Current hosts**:
- `2600AD` — Atari VCS 800; workstation/gaming node; ZFS on LUKS, Hyprland (via UWSM) with greetd/regreet, WireGuard client, Syncthing client; activated with `sudo nixos-rebuild switch --flake .#2600AD`
- `HALLpass.space` — Minimal VPS; WireGuard hub + Syncthing introducer/relay/discovery; nginx front; **not yet deployed** (contains placeholder values); activated with `sudo nixos-rebuild switch --flake .#HALLpass.space`
- `HelloMoto` — Android phone (Termux + Nix, `aarch64-linux`); standalone Home Manager only; WireGuard and Syncthing via Android apps; activated with `home-manager switch --flake .#HelloMoto`

### User Model
`users.users.<name>` in `configuration.nix` defines the account and group membership. Home Manager (`hosts/<host>/home/<user>.nix`) handles both package installation (`home.packages`) and dotfile/app configuration. There is no roles module in use.

Guest user on 2600AD has an ephemeral tmpfs `/home/guest` (wiped on reboot); its packages are defined directly on `users.users.guest.packages` in `configuration.nix` since Home Manager persistence is pointless for a guest.

### Networking (2600AD)
2600AD currently uses NetworkManager (`networking.networkmanager.enable = true`) as a temporary fallback while systemd-networkd configuration is being stabilized. The plan is to return to `networking.useNetworkd = true` with iwd for WiFi once the Hyprland desktop is confirmed working. WiFi PSK will be a sops secret deployed to `/var/lib/iwd/<SSID>.psk`.

### Display Manager (2600AD)
2600AD uses **greetd + regreet** (GTK4 Wayland-native greeter) instead of GDM. The greeter runs on cage (minimal Wayland compositor) and provides user selection, password entry, and session dropdown. Hyprland is launched via UWSM (Universal Wayland Session Manager).

### Desktop Environment (HALLwayDE)
The Hyprland desktop environment is managed by [HALLwayDE](https://github.com/MarkusBitterman/HALLwayDE), a NixOS port of HyDE (HyprDots Environment). HALLwayDE is imported as a flake input and consumed as a Home Manager module.

**Integration**: The module is imported in `hosts/<host>/home/<user>.nix`:
```nix
{ inputs, ... }:
{
  imports = [ inputs.hallwayde.homeManagerModules.default ];

  hallwayde = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@60,0x0,1";
    keyboard = "us";
    # extraMonitors = [ "DP-1,2560x1440@144,1920x0,1" ];
  };
}
```

**What HALLwayDE manages**: Hyprland config, waybar, rofi, dunst, hyprlock, wlogout, theming, keybindings, and autostart applications. Do not duplicate these in the host's Home Manager config.

**Upstream**: HALLwayDE is maintained separately at `github:MarkusBitterman/HALLwayDE`. To update: `nix flake update hallwayde`.

### WireGuard Overlay
The HALLpass WireGuard subnet is `10.23.11.0/24`:
- `10.23.11.1` — HALLpass.space (hub)
- `10.23.11.80` — 2600AD
- `10.23.11.64` — HelloMoto (phone)

### Secrets (sops-nix)
Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix), using age encryption.

| File | Purpose |
|------|---------|
| `.sops.yaml` (repo root) | SOPS config — maps secrets files to recipient age public keys |
| `hosts/<host>/secrets.yaml` | Encrypted YAML with secret values |
| `hosts/<host>/secrets.nix` | NixOS module — declares runtime paths, owners, modes |

**Admin age key**: `~/.config/sops/age/keys.txt` (generated with `age-keygen`). The public key is in `.sops.yaml`.

**Editing secrets**: Run `sops hosts/2600AD/secrets.yaml` to decrypt, edit, and re-encrypt in one step.

**Adding a new secret**:
1. Add the key to `hosts/<host>/secrets.yaml` via `sops`
2. Declare it in `hosts/<host>/secrets.nix` with owner/mode
3. Reference via `config.sops.secrets."<name>".path`

Secrets are referenced in NixOS config via `config.sops.secrets."<name>".path`, in NixOS-backed Home Manager via `osConfig.sops.secrets."<name>".path`, and in standalone Home Manager (HelloMoto) via `config.sops.secrets."<name>".path` directly.

**Runtime decryption**: Uses the SSH host key (`/etc/ssh/ssh_host_ed25519_key`) converted to age format.

**Current gap**: HALLpass.space secrets are encrypted for the admin key only — the VPS host key is not yet known. After first VPS boot: get host key with `ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age`, add to `.sops.yaml`, then run `sops updatekeys hosts/HALLpass.space/secrets.yaml`.

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
1. Create `hosts/<hostname>/` with `configuration.nix`, `hardware-configuration.nix`, `secrets.nix`, `secrets.yaml`, `home/<user>.nix`
2. Register in `flake.nix` under `nixosConfigurations.<hostname>`
3. Add host's age public key to `.sops.yaml` and create `secrets.yaml` with `sops`

### Placeholder Values
Several config values in `hosts/HALLpass.space/configuration.nix` and `hosts/2600AD/configuration.nix` are not yet populated — they are literal placeholder strings that must be replaced before deployment is functional:
- `HALLPASS_WG_PUBLIC_KEY` / `DESKTOP_WG_PUBLIC_KEY` / `PHONE_WG_PUBLIC_KEY` — WireGuard public keys
- `HALLPASS_SYNCTHING_DEVICE_ID` / `PHONE_SYNCTHING_DEVICE_ID` — Syncthing device IDs
- `DISCOVERY_SERVER_ID` / `RELAY_SERVER_ID` — Syncthing infra IDs from HALLpass.space startup logs

See `docs/secrets.md` for the full workflow on deriving and filling these in.
