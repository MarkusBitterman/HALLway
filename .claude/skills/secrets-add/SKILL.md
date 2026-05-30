---
name: secrets-add
description: Add a new sops-nix secret to a host — generate value, update secrets.yaml, declare in secrets.nix, and document in docs/secrets.md
disable-model-invocation: true
---

# secrets-add

Add a new secret to a HALLway host.

## Usage

```
/secrets-add <hostname> <secret-name> [--type ssh|wg|psk|token|file]
```

Type is auto-detected from name prefix if not provided:
- `ssh_key_*` → ssh (generates ed25519 keypair)
- `wg_*` (not psk) → wg (generates WireGuard keypair)
- `*psk*` → psk (generates WireGuard PSK)
- anything else → token/file (externally sourced)

## Steps

### 1. Detect or confirm type

If type is ambiguous, ask the user to confirm.

### 2. Generate the value (if auto-generatable)

Run in the HALLway dev shell:

```bash
# Enters shell and runs rotate-key
nix develop --command rotate-key <secret-name>
```

This will:
- **ssh**: create `~/.ssh/<secret-name>` + print public key for external registration
- **wg**: print private key (for secrets.yaml) + public key (for peer's configuration.nix)
- **psk**: print symmetric key (goes into both peer secrets.yaml files)

For externally sourced secrets (tokens, API keys, files), ask the user to obtain the value.

### 3. Insert into secrets.yaml

Instruct the user to run:

```bash
sops hosts/<hostname>/secrets.yaml
```

Tell them exactly what to add — the key name and format. For multi-line values (SSH private keys):

```yaml
ssh_key_<name>: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <base64>
    -----END OPENSSH PRIVATE KEY-----
```

For single-line values:

```yaml
<secret-name>: <value>
```

Wait for the user to confirm they've saved and closed sops before proceeding.

### 4. Declare in secrets.nix

Add the declaration to `hosts/<hostname>/secrets.nix`.

**NixOS host pattern** (owner = primary user, root for system secrets):

```nix
# ─────────────────────────────────────────────────────────────────────────
# <Category>
# ─────────────────────────────────────────────────────────────────────────
sops.secrets."<secret-name>" = {
  owner = "<primary-user>";
  group = "users";
  mode = "0600";
};
```

**WireGuard / system-owned secrets** (root):

```nix
sops.secrets."<secret-name>" = {
  owner = "root";
  group = "root";
  mode = "0400";
};
```

**Custom path secrets** (e.g., WiFi PSK):

```nix
sops.secrets."<secret-name>" = {
  path = "/var/lib/iwd/<SSID>.psk";
  owner = "root";
  group = "root";
  mode = "0600";
};
```

**Standalone Home Manager** (HelloMoto — no owner/group):

```nix
sops.secrets."<secret-name>" = {
  mode = "0600";
};
```

### 5. Add wiring stub (if applicable)

If the secret is referenced by a known service (SSH key → `programs.ssh`, WireGuard → `networking.wireguard`, token → `home.sessionVariables`), add the wiring reference. Otherwise, note where the user should reference it.

NixOS-backed Home Manager reference:
```nix
osConfig.sops.secrets."<secret-name>".path
```

NixOS config reference:
```nix
config.sops.secrets."<secret-name>".path
```

Standalone Home Manager:
```nix
config.sops.secrets."<secret-name>".path
```

### 6. Document in docs/secrets.md

Add a row to the appropriate host table in `docs/secrets.md`:

```markdown
| `<secret-name>` | <description> | `rotate-key <secret-name>` / external |
```

### 7. Rekey check

If a new age recipient was added to `.sops.yaml` for this host, remind the user:

```bash
sops updatekeys hosts/<hostname>/secrets.yaml
```

This is only needed when adding a NEW host key to `.sops.yaml`, not for routine secret additions.

### 8. Validate

```bash
nix flake check
```
