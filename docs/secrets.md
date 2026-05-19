# 🔐 HALLway Secrets Management

HALLway uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets as age-encrypted YAML files committed to the repository. No plaintext secrets ever touch version control.

---

## 📖 Table of Contents

- [How It Works](#-how-it-works)
- [Key Files](#-key-files)
- [Security Model](#-security-model)
- [Setup](#-setup)
- [Secrets Reference](#-secrets-reference)
- [Common Tasks](#-common-tasks)
- [Multi-Host Workflow](#-multi-host-workflow)
- [Troubleshooting](#-troubleshooting)

---

## 🔄 How It Works

| Phase | Who | What happens |
|-------|-----|--------------|
| **Edit** | You, manually | `sops hosts/<host>/secrets.yaml` decrypts → you edit → sops re-encrypts on save |
| **Deploy** | `nixos-rebuild switch` | sops-nix decrypts secrets to `/run/secrets/` with correct owner/mode |

> 💡 `sops` is **not** run by the build system. You edit once, deploy many times.

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `.sops.yaml` | Maps secrets files → age public keys (who can decrypt what) |
| `hosts/<host>/secrets.yaml` | Encrypted secrets (committed to git) |
| `hosts/<host>/secrets.nix` | Declares runtime paths, owners, modes |

All three are committed to git. Only `secrets.yaml` contains actual secret data (encrypted).

---

## 🛡️ Security Model

**Each host can only decrypt its own secrets.**

```
┌─────────────────────────────────────────────────────────────┐
│  .sops.yaml                                                 │
│                                                             │
│  keys:                                                      │
│    - &admin      age1xxx...  ← 🔑 Your workstation          │
│    - &host_2600AD age1yyy... ← 🖥️ 2600AD host key           │
│    - &host_hallpass age1zzz... ← 🌐 HALLpass.space host key │
│                                                             │
│  creation_rules:                                            │
│    - path: hosts/2600AD/secrets.yaml                        │
│      keys: [admin, host_2600AD]     ✅ Can decrypt          │
│                                                             │
│    - path: hosts/HALLpass.space/secrets.yaml                │
│      keys: [admin, host_hallpass]   ✅ Can decrypt          │
└─────────────────────────────────────────────────────────────┘
```

- **Admin key** → Can edit ALL secrets (lives on your workstation)
- **Host keys** → Can only decrypt THEIR OWN secrets at runtime
- HALLpass.space ❌ cannot read 2600AD secrets (and vice versa)

This is intentional. If a server is compromised, it can't leak other hosts' secrets.

---

## 🚀 Setup

### Admin Key (your workstation)

Generate once, keep forever:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Prints: Public key: age1xxxxx...
```

Add the public key to `.sops.yaml` under `keys:` as `&admin`.

### Host Key (each NixOS host)

Get the age-format public key from the SSH host key:

```bash
# On the host:
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Or remotely:
ssh-keyscan hostname | grep ed25519 | ssh-to-age
```

Add to `.sops.yaml` under `keys:` and include in that host's `creation_rules`.

### Enable Local Editing on a Remote Host

By default, only your workstation can edit secrets. To let a host edit its own secrets:

```bash
# On the remote host:
sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Now `sops hosts/<this-host>/secrets.yaml` works locally. The host still can't edit other hosts' secrets.

---

## 📋 Secrets Reference

### 2600AD

| Key | What it is | How to generate |
|-----|------------|-----------------|
| `ssh_key_github` | GitHub SSH key | `ssh-keygen -t ed25519 -C "bittermang@2600AD"` |
| `ssh_key_hobbs` | Hobbs server SSH key | `ssh-keygen -t ed25519` |
| `ssh_key_hallpass` | HALLpass.space SSH key | `ssh-keygen -t ed25519` |
| `github_token` | GitHub PAT | [GitHub Settings](https://github.com/settings/tokens) |
| `gpg_key` | GPG private key (armored) | `gpg --export-secret-keys --armor <ID>` |
| `wg_privatekey` | WireGuard client key | `wg genkey` |
| `wg_psk` | WireGuard PSK (shared with server) | `wg genpsk` |
| `syncthing_gui_pass` | Syncthing GUI password | Choose one |
| `vultr_api_key` | Vultr API key | [Vultr Settings](https://my.vultr.com/settings/#settingsapi) |
| `wifi_home` | iwd PSK file | See below |

### HALLpass.space

| Key | What it is | How to generate |
|-----|------------|-----------------|
| `ssh_key_github` | GitHub SSH key | `ssh-keygen -t ed25519 -C "matt@hallpass.space"` |
| `wg_privatekey` | WireGuard server key | `wg genkey` |
| `wg_desktop_psk` | WireGuard PSK for 2600AD | `wg genpsk` (same as 2600AD's `wg_psk`) |
| `syncthing_gui_pass` | Syncthing GUI password | Choose one |
| `acme_vultr_api_key` | Vultr API for ACME DNS-01 | [Vultr Settings](https://my.vultr.com/settings/#settingsapi) |

---

## 🛠️ Common Tasks

### Edit Secrets

```bash
nix develop
sops hosts/2600AD/secrets.yaml
```

### YAML Structure

```yaml
# Single-line values
github_token: ghp_xxxxxxxxxxxxx
syncthing_gui_pass: mypassword

# Multi-line values (SSH keys, certificates)
ssh_key_github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----

# iwd WiFi PSK
wifi_home: |
    [Security]
    Passphrase=your-wifi-password
```

### Generate WireGuard Keys

```bash
# Generate keypair
wg genkey | tee privatekey | wg pubkey > publickey

# Private key → secrets.yaml
sops hosts/2600AD/secrets.yaml
# Add: wg_privatekey: <contents of privatekey>

# Public key → configuration.nix (not a secret)
cat publickey
```

### Generate PSK (shared secret between peers)

```bash
wg genpsk > psk.txt
# Add same value to BOTH hosts' secrets.yaml
```

---

## 🌐 Multi-Host Workflow

### Adding a New Host

1. **Get the host's age public key:**
   ```bash
   ssh-keyscan newhost.example.com | grep ed25519 | ssh-to-age
   ```

2. **Add to `.sops.yaml`:**
   ```yaml
   keys:
     - &host_newhost age1xxxxx...

   creation_rules:
     - path_regex: hosts/newhost/secrets\.yaml$
       key_groups:
         - age:
             - *admin
             - *host_newhost
   ```

3. **Create secrets file:**
   ```bash
   nix develop
   sops hosts/newhost/secrets.yaml
   # Add your secrets, save
   ```

### Rekeying (after adding a host key)

⚠️ **Run from your workstation** (where admin key exists):

```bash
nix develop
sops updatekeys hosts/<host>/secrets.yaml
git add .sops.yaml hosts/<host>/secrets.yaml
git commit -m "chore: rekey for new host"
git push
```

Then pull on the remote host.

### First VPS Deployment

```bash
# 1. Deploy with secrets encrypted for admin only
#    (host key not known yet)

# 2. After first boot, get host key:
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age

# 3. Add to .sops.yaml, uncomment in creation_rules

# 4. Rekey FROM YOUR WORKSTATION:
sops updatekeys hosts/HALLpass.space/secrets.yaml

# 5. Commit, push, pull on server

# 6. (Optional) Enable local editing on server:
sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

---

## 🔍 Runtime Paths

Secrets are decrypted to `/run/secrets/<name>` at activation. Reference in Nix:

```nix
# In configuration.nix:
config.sops.secrets."wg_privatekey".path

# In Home Manager (NixOS-backed):
osConfig.sops.secrets."github_token".path

# In standalone Home Manager:
config.sops.secrets."github_token".path
```

---

## 🐛 Troubleshooting

### "Failed to get data key"

Your key can't decrypt the file.

**On workstation:**
- Check `~/.config/sops/age/keys.txt` exists
- Verify your public key is in `.sops.yaml` for this file

**On remote host:**
- You're trying to edit a different host's secrets (not allowed)
- Or the file hasn't been rekeyed to include this host yet

### "no identity matched any of the recipients"

The host key isn't in the recipient list yet.

**Fix:** Run from your workstation:
```bash
sops updatekeys hosts/<host>/secrets.yaml
```

### Can't edit secrets on remote host

1. Is the host key in `.sops.yaml` creation_rules? (not just in `keys:`)
2. Did you run `sops updatekeys` from your workstation?
3. Did you set up local age key?
   ```bash
   sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > ~/.config/sops/age/keys.txt
   ```

### Empty secrets file

`sops` creates an empty encrypted file by default. Just edit it:
```bash
sops hosts/<host>/secrets.yaml
```

---

## 📚 Related

- [HALLpass.space README](../hosts/HALLpass.space/README.md) — VPS deployment workflow
- [2600AD README](../hosts/2600AD/README.md) — Workstation setup
- [sops-nix docs](https://github.com/Mic92/sops-nix) — Upstream documentation
