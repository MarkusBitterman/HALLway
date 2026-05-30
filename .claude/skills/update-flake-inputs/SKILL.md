---
name: update-flake-inputs
description: Update Nix flake inputs (all or specific) with validation and commit. Run after upstream fixes or periodically for security patches.
disable-model-invocation: true
---

# update-flake-inputs

Update one or more flake inputs, validate, format, and commit.

## Usage

```
/update-flake-inputs [input-name ...]
```

- No args → update ALL inputs
- `nixpkgs` → update only nixpkgs
- `doorwayde` → update only DOORwayDE
- `home-manager sops-nix` → space-separated list

## Steps

### 1. Update

```bash
# Single or specific inputs
nix flake update <input>

# All inputs
nix flake update
```

### 2. Show what changed

```bash
git diff flake.lock | grep -A1 '"rev"'
```

Report which inputs changed and their new revisions to the user.

### 3. Validate

```bash
nix flake check
```

If check fails, revert and report the error:

```bash
git checkout -- flake.lock
```

### 4. Format

```bash
nix fmt
```

### 5. Commit

Use the commit-commands:commit skill or run git directly:

```
chore: update <input> flake input        # single
chore: update <a>, <b> flake inputs      # multiple
chore: update all flake inputs           # all
```

## Post-update notes

- **nixpkgs**: Check for breaking changes in NixOS module options if `nix flake check` raises warnings
- **doorwayde**: Rebuild 2600AD to verify DOORwayDE integration — `sudo nixos-rebuild switch --flake .#2600AD`
- **home-manager**: `home.stateVersion` pins behavior; no action needed unless bumping it intentionally
- **sops-nix**: Generally safe; verify secrets still decrypt after rebuild
