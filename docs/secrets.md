# HALLway Secrets Management

HALLway uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets as
age-encrypted YAML files committed to the repository. No plaintext secrets ever
touch version control.

---

## The Two-Phase Model

| Phase | Who triggers it | What happens |
|-------|----------------|--------------|
| **Create / Edit** | You, manually, once | `sops hosts/<host>/secrets.yaml` opens `$EDITOR` with decrypted YAML; on save sops re-encrypts for all recipients in `.sops.yaml`. |
| **Deploy** | `nixos-rebuild switch`, automatically | The sops-nix NixOS module decrypts each secret and places it at the path / owner / mode declared in `hosts/<host>/secrets.nix`. |

> `sops` is **not** run by the build system. You run it once per secret edit.
> Every subsequent `nixos-rebuild` just decrypts the existing file.

### Bootstrapping before the flake is active

You don't need to deploy the flake first. Run `nix develop` from the repo root
to enter the dev shell — this provides `sops`, `age`, and sets `SOPS_AGE_KEY_FILE`.
Create all secrets before the first `nixos-rebuild switch`.

---

## Key Files

| File | Purpose | Used by |
| ---- | ------- | ------- |
| `.sops.yaml` (repo root) | SOPS config — maps secrets files to recipient age keys | `sops` CLI |
| `hosts/<host>/secrets.yaml` | Encrypted YAML with secret values | `sops` CLI |
| `hosts/<host>/secrets.nix` | NixOS module — declares runtime paths, owners, modes | `nixos-rebuild switch` |

All three must be committed to git.

---

## Admin Key Setup

The admin age key lives at `~/.config/sops/age/keys.txt`. Generate it once:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Prints: Public key: age1xxxxx...
```

The public key goes in `.sops.yaml` under `keys:`. The private key stays in
`keys.txt` and never leaves your machine.

### Host Key

Each NixOS host uses its SSH host key for runtime decryption. Get the age
format of the host key:

```bash
# On the host itself:
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Or remotely:
ssh-keyscan hostname | grep ed25519 | ssh-to-age
```

Add this to `.sops.yaml` under `keys:` and include it in the host's
`creation_rules` entry.

---

## Secrets Reference

### 2600AD

Secrets are stored in `hosts/2600AD/secrets.yaml`:

| Key in YAML | What it is | How to generate |
| ----------- | ---------- | --------------- |
| `ssh_key_github` | SSH private key for GitHub | `ssh-keygen -t ed25519 -C "bittermang@2600AD"` |
| `ssh_key_hobbs` | SSH private key for hobbs server | `ssh-keygen -t ed25519` |
| `ssh_key_hallpass` | SSH private key for hallpass server | `ssh-keygen -t ed25519` |
| `github_token` | GitHub personal access token | [GitHub Settings → PAT](https://github.com/settings/tokens) |
| `gpg_key` | GPG private key (armored) | `gpg --export-secret-keys --armor <KEY_ID>` |
| `wg_2600ad_privatekey` | WireGuard client private key | `wg genkey` |
| `wg_hallspace_psk` | WireGuard preshared key | `wg genpsk` |
| `syncthing_gui_pass` | Syncthing GUI password | Choose a password |
| `wifi_home` | iwd PSK file content | See WiFi section below |

### HALLpass.space

Secrets are stored in `hosts/HALLpass.space/secrets.yaml`:

| Key in YAML | What it is | How to generate |
| ----------- | ---------- | --------------- |
| `ssh_key_github` | SSH private key for GitHub | `ssh-keygen -t ed25519 -C "matt@hallpass.space"` |
| `wg_hallpass_privatekey` | WireGuard server private key | `wg genkey` |
| `syncthing_gui_pass` | Syncthing GUI password | Choose a password |

---

## Creating / Editing Secrets

```bash
# Enter dev shell (sets SOPS_AGE_KEY_FILE)
nix develop

# Edit secrets (decrypts, opens editor, re-encrypts on save)
sops hosts/2600AD/secrets.yaml
```

The YAML structure:
```yaml
ssh_key_github: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...key content...
    -----END OPENSSH PRIVATE KEY-----
github_token: ghp_xxxxxxxxxxxxx
syncthing_gui_pass: mypassword
wifi_home: |
    [Security]
    Passphrase=my-wifi-password
```

Use `|` for multiline values (SSH keys, WiFi PSK). Use plain strings for tokens.

---

## WireGuard Keys

WireGuard **private keys** are secrets in `secrets.yaml`. **Public keys** are
plain strings in configuration files.

```bash
# Generate keypair
wg genkey | tee privatekey | wg pubkey > publickey

# Add private key to secrets.yaml
sops hosts/2600AD/secrets.yaml
# Add: wg_2600ad_privatekey: <contents of privatekey>

# Put public key in configuration.nix
cat publickey
# Replace placeholder: DESKTOP_WG_PUBLIC_KEY
```

---

## WiFi PSK (iwd format)

The `wifi_home` secret is an iwd PSK file:

```yaml
wifi_home: |
    [Security]
    Passphrase=your-wifi-password-here
```

Update the SSID in `hosts/2600AD/secrets.nix` to match your network name.

---

## Adding Recipients (Rekeying)

When adding a new host or rotating keys:

1. Add the new age public key to `.sops.yaml` under `keys:`
2. Update the `creation_rules` to include the new key
3. Rekey the secrets file:

```bash
sops updatekeys hosts/<host>/secrets.yaml
```

### After VPS Provisioning

Once HALLpass.space is deployed:

```bash
# 1. Get VPS host key
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# → age1xxxxx...

# 2. Add to .sops.yaml
#    - Add key under keys: as &host_hallpass
#    - Uncomment in creation_rules for HALLpass.space

# 3. Rekey
sops updatekeys hosts/HALLpass.space/secrets.yaml

# 4. Commit
git add .sops.yaml hosts/HALLpass.space/secrets.yaml
git commit -m "feat: add HALLpass.space host key and rekey"
```

---

## Secret Paths at Runtime

Secrets are decrypted to `/run/secrets/<name>` at activation time. Reference
them in NixOS config:

```nix
# In configuration.nix:
config.sops.secrets."wg_2600ad_privatekey".path

# In Home Manager (NixOS-backed):
osConfig.sops.secrets."github_token".path

# In standalone Home Manager:
config.sops.secrets."github_token".path
```

---

## Syncthing Device IDs (Not Secrets)

Syncthing device IDs are public identifiers, not secrets. Obtain after first
deployment:

```bash
# On HALLpass.space:
syncthing cli show system | jq -r .myID
# → Replace HALLPASS_SYNCTHING_DEVICE_ID in 2600AD config

# Discovery/relay IDs from logs:
journalctl -u syncthing-discovery | grep -i deviceid
journalctl -u syncthing.service | grep -i relay
```

---

## Troubleshooting

### "Failed to get data key"

Your admin key can't decrypt the file. Check:
- `~/.config/sops/age/keys.txt` exists and contains a valid age private key
- The key format is correct (starts with `AGE-SECRET-KEY-`, no extra lines)
- Your public key is in `.sops.yaml` for this file's `creation_rules`

### "no identity matched any of the recipients"

The runtime host key isn't in the recipient list. Run:
```bash
sops updatekeys hosts/<host>/secrets.yaml
```

### Empty secrets file

`sops` creates an empty encrypted file by default. Edit it to add secrets:
```bash
sops hosts/<host>/secrets.yaml
```

---

## VS Code Integration

The dev shell opens secrets in VS Code by default (`EDITOR="code --wait"`).

For quick status of secrets files:
```bash
ls -la hosts/*/secrets.yaml
```
