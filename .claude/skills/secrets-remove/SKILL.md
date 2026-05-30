---
name: secrets-remove
description: Remove a sops-nix secret from a host — find all references, guide sops edit, clean secrets.nix, remove docs row
disable-model-invocation: true
---

# secrets-remove

Remove a secret from a HALLway host completely and cleanly.

## Usage

```
/secrets-remove <hostname> <secret-name>
```

## Steps

### 1. Find all references

Search the host directory for every reference to this secret:

```bash
grep -rn '"<secret-name>"' hosts/<hostname>/
grep -rn 'sops.secrets."<secret-name>"' hosts/<hostname>/
grep -rn 'config.sops.secrets."<secret-name>"' hosts/<hostname>/
grep -rn 'osConfig.sops.secrets."<secret-name>"' hosts/<hostname>/
```

List every file and line number found. Do not proceed until the user has reviewed and confirmed the list.

### 2. Confirm with user

Present the full list of references:

```
Found references to "<secret-name>":
  hosts/<hostname>/secrets.nix:16 — sops.secrets declaration
  hosts/<hostname>/home/<user>.nix:49 — osConfig.sops.secrets."<secret-name>".path

Proceed with removal? (This will modify secrets.nix and home config, and prompt you to delete from secrets.yaml)
```

Wait for explicit user confirmation before modifying any file.

### 3. Remove the sops.secrets declaration from secrets.nix

Remove the entire `sops.secrets."<name>" = { ... };` block from `hosts/<hostname>/secrets.nix`, including any comment line immediately above it that belongs to it (e.g. `# WiFi PSK` or `# ─────` category dividers only if they'd become empty sections).

Do NOT remove section headers (`# ─────────`) if other secrets in that section remain.

### 4. Remove or stub wiring references

For each wiring reference found in step 1:

- If the reference is in `home.sessionVariables`, remove the key-value pair
- If the reference is in `programs.ssh.matchBlocks."host".identityFile`, remove the `identityFile` line
- If the reference is in `networking.wireguard`, remove the `privateKeyFile` or `presharedKeyFile` attribute
- If the full attribute set only contained this secret, remove the containing block
- If the reference is load-bearing (a service would break without it), note this and ask the user how to handle it rather than silently removing

### 5. Remove from secrets.yaml

Instruct the user to run:

```bash
sops hosts/<hostname>/secrets.yaml
```

Tell them to delete the key `<secret-name>` and its value, save, and close. Wait for user to confirm done.

### 6. Remove from docs/secrets.md

Find and remove the row for `<secret-name>` in the appropriate host table in `docs/secrets.md`.

### 7. Validate

```bash
nix flake check
```

If check passes, the secret is fully removed. If it fails, report the error — it likely means a wiring reference was missed.
