# HALLpass.space: Installation Guide

**Target**: Minimal VPS (Vultr, 25GB disk)
**Role**: WireGuard hub + Syncthing introducer + web edge + Mercurial host
**TLS**: Wildcard `*.hallpass.space` via DNS-01 (Vultr API) — no HTTP-01, no per-domain certs

---

## TLS Strategy

This host uses a **DNS-01 ACME challenge** rather than HTTP-01. This means:

- A single wildcard cert covers `hallpass.space`, `hg.hallpass.space`, and any future subdomains
- Cert issuance does **not** require DNS A records to point at the server first — lego only needs the Vultr API key to create TXT records
- A records can be pointed at any time (before or after deploy)

The Vultr API key is stored as an agenix secret (`acme-vultr-api-key.age`). The key needs **DNS write permission** in the Vultr control panel.

---

## Pre-Flight Checklist

Before deploying, complete these steps from 2600AD:

### 1. Get the VPS SSH host key (for agenix rekey)

```bash
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# → age1xxxx...
```

Paste into `secrets.nix` (root): uncomment the `hallpass` variable, fill in the key, and add `hallpass` to the three HALLpass.space `publicKeys` lists. Then rekey:

```bash
nix develop
agenix -r -i ~/.ssh/id_hallpass
```

### 2. Create the Vultr API key secret

Get a Vultr API key with DNS write permission from the Vultr control panel.

```bash
nix develop

# Pipe approach — no editor needed when content is known:
echo "VULTR_API_KEY=your-vultr-api-key-here" \
  | age -R ~/.ssh/id_hallpass.pub \
  -o hosts/HALLpass.space/secrets/acme-vultr-api-key.age

# Or editor approach (opens $EDITOR, paste the line above, save and close):
rm -f hosts/HALLpass.space/secrets/acme-vultr-api-key.age
agenix -e hosts/HALLpass.space/secrets/acme-vultr-api-key.age -i ~/.ssh/id_hallpass
```

### 3. Create remaining secrets (if not already done)

```bash
agenix -e hosts/HALLpass.space/secrets/ssh_key_github.age     -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/syncthing-gui-pass.age -i ~/.ssh/id_hallpass
```

### 4. Commit and push

```bash
nix flake check
nix fmt
git add -A
git commit -m "feat: HALLpass.space deployment-ready"
git push origin main
```

---

## Deploy

From the VPS (SSH in as root or via console):

```bash
# Clone config
sudo mkdir -p /etc/nixos
cd /etc/nixos
sudo git clone https://github.com/MarkusBitterman/HALLway.git .

# Build and activate
sudo nixos-rebuild switch --flake .#HALLpass.space
```

Or directly from 2600AD if you already have SSH access:

```bash
ssh matt@hallpass.space "cd /etc/nixos && sudo nixos-rebuild switch --flake .#HALLpass.space"
```

On first activation:
- `systemd-tmpfiles` creates `/srv/hallspace/_public/` and `/srv/hg/repos/`
- agenix decrypts all secrets using the host's SSH key
- lego requests `*.hallpass.space` + `hallpass.space` cert via Vultr DNS-01
- nginx, hgweb, WireGuard (hub only until peers added), and Syncthing all start

---

## Post-Deploy

### Add VPS to agenix (if not done in pre-flight)

```bash
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# Uncomment hallpass in secrets.nix, fill key, add to HALLpass.space entries
agenix -r -i ~/.ssh/id_hallpass
```

### Collect Syncthing IDs for 2600AD config

```bash
ssh matt@hallpass.space

syncthing cli show system | jq -r .myID
# → replace HALLPASS_SYNCTHING_DEVICE_ID in hosts/2600AD/configuration.nix

journalctl -u syncthing-discovery | grep -i deviceid | tail -1
# → replace DISCOVERY_SERVER_ID

journalctl -u syncthing.service | grep -i relay | tail -1
# → replace RELAY_SERVER_ID
```

### Initialize Mercurial repos

```bash
ssh matt@hallpass.space "hg init /srv/hg/repos/hallway"
# Browse: https://hg.hallpass.space/hallway
```

### Point DNS A records (when ready for public access)

In Vultr DNS, add:
- `hallpass.space` A → VPS IP
- `hg.hallpass.space` A → VPS IP

The wildcard TLS cert is already issued regardless of when A records are set.

---

## Required Firewall Ports (Internet-Facing)

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | nginx (HTTP redirect to HTTPS) |
| 443 | TCP | nginx HTTPS |
| 51820 | UDP | WireGuard |

Syncthing relay/discovery ports (22000, 22067, 22070, 8443) are restricted to the WireGuard interface only.
