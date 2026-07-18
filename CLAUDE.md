# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix develop              # Enter dev shell (loads sops, age, etc.)
nix flake check          # Validate flake syntax — primary test command (Ctrl+Shift+T in VS Code)
nix fmt                  # Format all .nix files with nixfmt (RFC 166) — also auto-runs per-file via PostToolUse hook
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel  # Build without activating
nix run .                # Unified activation: detects the current host, runs the right switch command
nix run . -- HALLpass.space                         # Explicit target; from any other host this deploys the VPS remotely
sudo nixos-rebuild switch --flake .#2600AD          # Build and activate on 2600AD
nixos-rebuild switch --flake .#HALLpass.space --target-host matt@hallpass.space --elevate=sudo --ask-elevate-password  # Build locally on 2600AD, deploy to VPS (no local sudo — it breaks SSH key resolution)
sops hosts/2600AD/secrets.yaml                      # Edit encrypted secrets (decrypt/edit/re-encrypt)
sops updatekeys hosts/2600AD/secrets.yaml           # Rekey after adding recipients to .sops.yaml
nix flake update                                    # Update all inputs to latest
nix flake update <input>                            # Update single input (e.g., doorway, nixpkgs)
```

Always run `nix flake check` and `nix fmt` before committing.

## Skills

Available Claude Code skills — invoke with the `/` prefix:

| Skill | Purpose |
|-------|---------|
| `/update-flake-inputs [input]` | Update one or all flake inputs, validate, commit |
| `/add-host <hostname> [--type]` | Provision new host: templates, flake.nix entry, .sops.yaml stub |
| `/secrets-add <hostname> <name>` | Add a new sops secret with value generation and docs row |
| `/secrets-remove <hostname> <name>` | Remove secret and all wiring references |
| `/secrets-rotate <hostname> <name>` | Rotate secret value, print new public key |

**When to update inputs**: After changing input URLs in `flake.nix`, when upstream fixes are needed, or periodically for security patches. The `flake.lock` file pins exact revisions — `nix flake update` refreshes them.

## Architecture

### Flake (`flake.nix`)
Entry point. Defines `nixosConfigurations` (NixOS hosts), `homeConfigurations` (non-NixOS hosts), `devShells.default`, and `apps.default` (the `nix run .` unified activation script). `nixosModules.default` (imported by every NixOS host and exported for other flakes) aggregates the shared modules:
- `modules/base.nix` — shared baseline via `lib.mkDefault`: systemd-boot + EFI vars, zram, nix settings (flakes, store optimization), locale, firewall, AppArmor, OpenSSH, zsh. Hosts override with plain assignments.
- `modules/mesh.nix` — `hallway.mesh` options registry: WireGuard overlay IPs/public keys, hub endpoint and Syncthing infra IDs, per-host Syncthing device IDs. Single source of truth — host configs read `config.hallway.mesh.*` instead of hardcoding peer values. Public identifiers only; private material stays in sops.

**Inputs**: `nixpkgs` (unstable), `home-manager`, `sops-nix`, `flake-utils`, `doorway`

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

### Boot Configuration (HALLpass.space)
HALLpass.space (VPS) uses **systemd-boot** as the EFI bootloader with EFI variable write support enabled. The latest stable kernel is used (`pkgs.linuxPackages_latest`) to ensure compatibility with modern VPS hardware and security patches.

### User Model
`users.users.<name>` in `configuration.nix` defines the account and group membership. Home Manager (`hosts/<host>/home/<user>.nix`) handles both package installation (`home.packages`) and dotfile/app configuration. There is no roles module in use.

Guest user on 2600AD has an ephemeral tmpfs `/home/guest` (wiped on reboot); its packages are defined directly on `users.users.guest.packages` in `configuration.nix` since Home Manager persistence is pointless for a guest.

### Security & Gaming (2600AD)
**Steam + Bubblewrap**: Steam's `gamescopeSession` uses bubblewrap (bwrap) for sandboxing. The bwrap binary in nixpkgs is compiled with `--disable-setuid`, so unprivileged user namespaces must be used. A setuid wrapper is disabled via `security.wrappers.bwrap = lib.mkForce { setuid = false; }` to prevent immediate crashes.

### Networking (2600AD)
2600AD currently uses NetworkManager (`networking.networkmanager.enable = true`) as a temporary fallback while systemd-networkd configuration is being stabilized. The plan is to return to `networking.useNetworkd = true` with iwd for WiFi once the Hyprland desktop is confirmed working. WiFi PSK will be a sops secret deployed to `/var/lib/iwd/<SSID>.psk`.

### Display Manager (2600AD)
2600AD uses **greetd + regreet** (GTK4 Wayland-native greeter) instead of GDM. The greeter runs on cage (minimal Wayland compositor) and provides user selection, password entry, and session dropdown. Hyprland is launched via UWSM (Universal Wayland Session Manager).

**Gnome Keyring Integration**: `services.gnome.gnome-keyring.enable` and `security.pam.services.greetd.enableGnomeKeyring` are enabled for PAM-based authentication (e.g., SSH key passphrases) during the greeter session.

### Desktop Environment (DOORway)
The Hyprland desktop environment is managed by [DOORway](https://github.com/MarkusBitterman/DOORway), a NixOS port of HyDE (HyprDots Environment). DOORway is imported as a flake input and consumed as a Home Manager module.

**Integration**: The module is imported in `hosts/<host>/home/<user>.nix`. Display configuration uses Hyprland monitor syntax:
```nix
{ inputs, ... }:
{
  imports = [ inputs.doorway.homeManagerModules.default ];

  doorway = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@59.85,0x0,1";  # Format: <output>,<resolution>@<refresh>,<offset>,<scale>
    keyboard = "us";
    # extraMonitors = [ "DP-1,2560x1440@144,1920x0,1" ];
  };
}
```

On 2600AD, the primary monitor is HDMI-A-1 at 1920x1080 (59.85 Hz). Adjust the `monitor` string for different outputs/resolutions.

**What DOORway manages**: Hyprland config, waybar, rofi, dunst, hyprlock, wlogout, theming, keybindings, and autostart applications. Do not duplicate these in the host's Home Manager config.

**Hyprland configType**: DOORway requires `wayland.windowManager.hyprland.configType = "lua"` (set in every DOORway-enabled user). Non-DOORway users (e.g. `guest`) use `configType = "hyprlang"`. Mixing these causes Hyprland to fail to start.

**Upstream**: DOORway is maintained separately at `github:MarkusBitterman/DOORway`. To update: `nix flake update doorway`.

### WireGuard Overlay
The HALLpass WireGuard subnet is `10.23.11.0/24`:
- `10.23.11.1` — HALLpass.space (hub)
- `10.23.11.80` — 2600AD
- `10.23.11.64` — HelloMoto (phone)

These values (plus public keys, hub endpoint, and Syncthing IDs) are defined once in `modules/mesh.nix` (`hallway.mesh`) and consumed by host configs — edit the registry, not the hosts.

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

**HALLpass.space host key**: Already rekeyed — `.sops.yaml` includes `&host_hallpass` and `hosts/HALLpass.space/secrets.yaml` is encrypted for both admin and host keys. To rotate after a reinstall: `ssh-keyscan -p 2222 hallpass.space | grep ed25519 | ssh-to-age` (sshd listens on 2222, not 22), add to `.sops.yaml`, then run `sops updatekeys hosts/HALLpass.space/secrets.yaml`.

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
All mesh identifiers now live in `modules/mesh.nix` (`hallway.mesh`). Remaining values to fill before the full mesh is functional:
- `hosts.phone.wgPublicKey` — literal placeholder `PHONE_WG_PUBLIC_KEY`; replace with the phone's WireGuard public key
- `hosts.hallpass.wgPublicKey` — provisional until HALLpass.space is deployed and its real key is generated

See `docs/secrets.md` for the full workflow on deriving and filling these in.
