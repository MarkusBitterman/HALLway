---
name: secrets-rotate
description: Rotate a sops-nix secret value — dispatch to rotate-key, guide sops edit, print new public key for external registration
disable-model-invocation: true
---

# secrets-rotate

Rotate the value of an existing secret on a HALLway host.

## Usage

```
/secrets-rotate <hostname> <secret-name>
```

## Steps

### 1. Detect type from name

Infer type from the secret name:

| Name pattern | Type | Action |
|---|---|---|
| `ssh_key_*` | SSH keypair | Generates new ed25519 keypair |
| `wg_*` (not psk) | WireGuard keypair | Generates new private + public key |
| `*psk*` | WireGuard PSK | Generates new symmetric key |
| anything else | External | Ask user to obtain new value |

If the name is ambiguous, ask the user to confirm the type.

### 2. Generate new value (auto-generatable types)

Run in the HALLway dev shell:

```bash
nix develop --command rotate-key <secret-name>
```

This dispatches based on the prefix:
- **ssh**: Writes new private key to `~/.ssh/<secret-name>`, prints the new public key
- **wg**: Prints new private key (for secrets.yaml) and new public key (for peer config)
- **psk**: Prints new symmetric key (must go into BOTH peers' secrets.yaml)

For externally sourced secrets (tokens, API keys, passwords): ask the user to obtain the new value from the appropriate service, then continue from step 3.

### 3. Display new public key for external registration

For SSH keys:
```
New public key for <secret-name>:
ssh-ed25519 AAAA... bittermang@2600AD

Register this at:
  - GitHub → Settings > SSH Keys (if replacing ssh_key_github_automation)
  - Remote server ~/.ssh/authorized_keys (if replacing a host access key)
```

For WireGuard keys — print new public key and remind the user which peer config to update:
```
New public key for <hostname>'s <secret-name>:
<public key>

Update the peer's AllowedPeers / publicKey in configuration.nix before deploying.
```

For PSKs — print key and remind that BOTH peers need to be updated:
```
New PSK:
<psk>

Add this to BOTH hosts' secrets.yaml (e.g. hosts/2600AD/secrets.yaml AND hosts/HALLpass.space/secrets.yaml).
```

Wait for user to confirm external registration is done before proceeding.

### 4. Update secrets.yaml

Instruct the user to run:

```bash
sops hosts/<hostname>/secrets.yaml
```

Tell them exactly what to replace — the key name and new value format:

For SSH private keys (multi-line):
```yaml
<secret-name>: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <base64>
    -----END OPENSSH PRIVATE KEY-----
```

For single-line values (WireGuard keys, PSKs, tokens):
```yaml
<secret-name>: <new-value>
```

Wait for the user to confirm they've saved and closed sops before proceeding.

### 5. Note: sops updatekeys NOT needed

Rotation only changes the secret value — it does NOT add or remove recipients. The same age keys listed in `.sops.yaml` are already applied. `sops updatekeys` is only needed when adding a NEW host or age key to the recipient list.

### 6. Rebuild

Remind the user to rebuild to pick up the new secret:

```bash
# On 2600AD:
sudo nixos-rebuild switch --flake .#2600AD

# On HALLpass.space:
sudo nixos-rebuild switch --flake .#HALLpass.space

# Standalone Home Manager (HelloMoto):
home-manager switch --flake .#HelloMoto
```

The new secret value is deployed to `/run/secrets/<name>` after activation.
