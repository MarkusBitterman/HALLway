# HALLpass.space

> HALLway host — minimal VPS, network hub and web edge

**Architecture**: x86_64
**Status**: Configuration complete; not yet deployed (placeholder values remain)

---

## Purpose

HALLpass.space is a small VPS (25GB class) that provides central infrastructure for all HALLway devices:

- **WireGuard hub** (`wg-hallspace`, `10.44.0.1/24`) — desktop and phone connect as peers
- **Syncthing introducer** — private relay (`strelaysrv`) and discovery (`stdiscosrv`) accessible only over WireGuard
- **Static web** (`hallpass.space`) — serves `/srv/hallspace/_public/`
- **Mercurial hosting** (`hg.hallpass.space`) — `hgweb` serving repos from `/srv/hg/repos/`; nginx TLS termination via ACME
- **SSH push target** — `hg clone ssh://matt@hallpass.space//srv/hg/repos/<name>`

## Configuration Model

- System config: [configuration.nix](configuration.nix)
- Home Manager user profile: [home/matt.nix](home/matt.nix)
- agenix secret mappings: [secrets.nix](secrets.nix)
- Hardware profile: [hardware-configuration.nix](hardware-configuration.nix)

## Security Baseline

- SSH: key-only auth, root login and password auth disabled; `AllowUsers = [ "matt" ]`
- Firewall: only `22/tcp`, `80/tcp`, `443/tcp`, `51820/udp` exposed publicly
- Syncthing infra ports allowed only on `wg-hallspace` interface
- AppArmor enabled
- Secrets managed by agenix

## Required Secrets

Encrypted files under [secrets/](secrets/):

| File | Contents |
|------|----------|
| `ssh_key_github.age` | SSH private key for GitHub operations |
| `wg-hallpass-privatekey.age` | WireGuard server private key |
| `syncthing-gui-pass.age` | Syncthing GUI password (plaintext; Syncthing hashes it) |

Create/edit with (from dev shell — sets `RULES` and `EDITOR` automatically):

```bash
nix develop
agenix -e hosts/HALLpass.space/secrets/ssh_key_github.age     -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/syncthing-gui-pass.age -i ~/.ssh/id_hallpass
```

> **Note**: these three secrets are currently encrypted for the admin key only. After first VPS boot, obtain the host SSH key with `ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age`, add it to the root `secrets.nix`, and rekey with `agenix -r -i ~/.ssh/id_hallpass`.

## Placeholder Values

| Placeholder | Location | How to get it |
|-------------|----------|---------------|
| `DESKTOP_WG_PUBLIC_KEY` | `configuration.nix` | `wg pubkey` from 2600AD keygen |
| `PHONE_WG_PUBLIC_KEY` | `configuration.nix` | WireGuard app on phone |

## Deploy

```bash
# From repo root
nix flake check
# Run on the VPS itself after nixos-install:
sudo nixos-rebuild switch --flake .#HALLpass.space
```

## Related

- 2600AD (WireGuard + Syncthing client): [../2600AD/configuration.nix](../2600AD/configuration.nix)
- Install guide: [INSTALLATION.md](INSTALLATION.md)
- Secrets workflow: [../../docs/secrets.md](../../docs/secrets.md)
