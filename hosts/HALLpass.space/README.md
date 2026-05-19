# HALLpass.space

> HALLway host — minimal VPS, network hub and web edge

**Architecture**: x86_64
**Status**: Configuration complete; not yet deployed (placeholder values remain)

---

## Table of Contents

- [Quick Start](#quick-start)
- [Purpose](#purpose)
- [Installation](#installation)
  - [Standard](#standard)
  - [Full Step-by-Step](#full-step-by-step)
- [How to Contribute](#how-to-contribute)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Already deployed?** Rebuild after config changes:

```bash
# From the VPS:
sudo nixos-rebuild switch --flake /etc/nixos#HALLpass.space

# Or from 2600AD via SSH:
ssh matt@hallpass.space "cd /etc/nixos && sudo nixos-rebuild switch --flake .#HALLpass.space"
```

**Fresh deploy?** See [Installation](#installation) below.

---

## Purpose

HALLpass.space is a small VPS (25GB class) that provides central infrastructure for all HALLway devices:

- **WireGuard hub** (`wg-hallspace`, `10.23.11.1/24`) — desktop and phone connect as peers
- **Syncthing introducer** — private relay (`strelaysrv`) and discovery (`stdiscosrv`) accessible only over WireGuard
- **Static web** (`hallpass.space`) — serves `/srv/hallspace/_public/`
- **Mercurial hosting** (`hg.hallpass.space`) — `hgweb` serving repos from `/srv/hg/repos/`; nginx TLS termination via ACME
- **SSH push target** — `hg clone ssh://matt@hallpass.space//srv/hg/repos/<name>`

## Configuration Model

- System config: [configuration.nix](configuration.nix)
- Home Manager user profile: [home/matt.nix](home/matt.nix)
- sops-nix secret mappings: [secrets.nix](secrets.nix)
- Hardware profile: [hardware-configuration.nix](hardware-configuration.nix)

## Security Baseline

- SSH: key-only auth, root login and password auth disabled; `AllowUsers = [ "matt" ]`
- Firewall: only `22/tcp`, `80/tcp`, `443/tcp`, `51820/udp` exposed publicly
- Syncthing infra ports allowed only on `wg-hallspace` interface
- AppArmor enabled
- Secrets managed by sops-nix

## Required Secrets

All secrets stored in `hosts/HALLpass.space/secrets.yaml`:

| Key | Contents |
|-----|----------|
| `ssh_key_github` | SSH private key for GitHub operations |
| `wg_hallpass_privatekey` | WireGuard server private key |
| `syncthing_gui_pass` | Syncthing GUI password (plaintext; Syncthing hashes it) |

Edit secrets:

```bash
nix develop
sops hosts/HALLpass.space/secrets.yaml
```

> **Note**: These secrets are currently encrypted for the admin key only. After first VPS boot, obtain the host SSH key with `ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age`, add it to `.sops.yaml`, and rekey with `sops updatekeys hosts/HALLpass.space/secrets.yaml`.

## Placeholder Values

| Placeholder | Location | How to get it |
|-------------|----------|---------------|
| `DESKTOP_WG_PUBLIC_KEY` | `configuration.nix` | `wg pubkey` from 2600AD keygen |
| `PHONE_WG_PUBLIC_KEY` | `configuration.nix` | WireGuard app on phone |

---

## Installation

**Target**: Minimal VPS (Vultr, 25GB disk)
**Role**: WireGuard hub + Syncthing introducer + web edge + Mercurial host
**TLS**: Wildcard `*.hallpass.space` via DNS-01 (Vultr API)

### Standard

This is a VPS deployment, not a bare-metal install. Clone the repo and run `nixos-rebuild switch`.

### Full Step-by-Step

#### TLS Strategy

This host uses a **DNS-01 ACME challenge** rather than HTTP-01:

- A single wildcard cert covers `hallpass.space`, `hg.hallpass.space`, and any future subdomains
- Cert issuance does **not** require DNS A records to point at the server first
- A records can be pointed at any time (before or after deploy)

#### Pre-Flight Checklist (from 2600AD)

**1. Get the VPS SSH host key (for sops rekey)**

```bash
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# → age1xxxx...
```

Add to `.sops.yaml`: uncomment the `hallpass` key anchor, fill in the value, add to HALLpass.space creation_rules. Then rekey:

```bash
nix develop
sops updatekeys hosts/HALLpass.space/secrets.yaml
```

**2. Edit secrets**

```bash
nix develop
sops hosts/HALLpass.space/secrets.yaml
```

Add the following keys to the YAML:

```yaml
ssh_key_github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...your GitHub deploy key...
    -----END OPENSSH PRIVATE KEY-----
wg_hallpass_privatekey: <output of wg genkey>
syncthing_gui_pass: your-strong-password
```

**3. Commit and push**

```bash
nix flake check
nix fmt
git add -A
git commit -m "feat: HALLpass.space deployment-ready"
git push origin main
```

#### Deploy

From the VPS (SSH in as root or via console):

```bash
# Clone config
sudo mkdir -p /etc/nixos
cd /etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .

# Build and activate
sudo nixos-rebuild switch --flake .#HALLpass.space
```

On first activation:
- `systemd-tmpfiles` creates `/srv/hallspace/_public/` and `/srv/hg/repos/`
- sops-nix decrypts all secrets using the host's SSH key
- lego requests `*.hallpass.space` + `hallpass.space` cert via Vultr DNS-01
- nginx, hgweb, WireGuard (hub only until peers added), and Syncthing all start

#### Post-Deploy

**Add VPS to sops (if not done in pre-flight)**

```bash
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# Add to .sops.yaml, update creation_rules
sops updatekeys hosts/HALLpass.space/secrets.yaml
```

**Collect Syncthing IDs for 2600AD config**

```bash
ssh matt@hallpass.space

syncthing cli show system | jq -r .myID
# → replace HALLPASS_SYNCTHING_DEVICE_ID in hosts/2600AD/configuration.nix

journalctl -u syncthing-discovery | grep -i deviceid | tail -1
# → replace DISCOVERY_SERVER_ID

journalctl -u syncthing.service | grep -i relay | tail -1
# → replace RELAY_SERVER_ID
```

**Initialize Mercurial repos**

```bash
ssh matt@hallpass.space "hg init /srv/hg/repos/hallway"
# Browse: https://hg.hallpass.space/hallway
```

**Point DNS A records (when ready for public access)**

In Vultr DNS, add:
- `hallpass.space` A → VPS IP
- `hg.hallpass.space` A → VPS IP

The wildcard TLS cert is already issued regardless of when A records are set.

---

## How to Contribute

See [CONTRIBUTING.md](../../CONTRIBUTING.md) in the repository root for:

- Dev environment setup
- Code style guidelines
- Pull request process

---

## Troubleshooting

### Required Firewall Ports (Internet-Facing)

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | nginx (HTTP redirect to HTTPS) |
| 443 | TCP | nginx HTTPS |
| 51820 | UDP | WireGuard |

Syncthing relay/discovery ports (22000, 22067, 22070, 8443) are restricted to the WireGuard interface only.

### ACME certificate not issued

Check lego logs:

```bash
journalctl -u acme-hallpass.space.service
```

Ensure the Vultr API key has DNS write permission.

### WireGuard peers not connecting

Verify peer public keys are correctly filled in `configuration.nix` and firewall allows UDP 51820.

---

## Related

- 2600AD (WireGuard + Syncthing client): [../2600AD/README.md](../2600AD/README.md)
- Secrets workflow: [../../docs/secrets.md](../../docs/secrets.md)
