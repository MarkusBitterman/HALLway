---
name: add-host
description: Provision a new HALLway host — create directory structure, fill templates, register in flake.nix, add .sops.yaml entry
disable-model-invocation: true
---

# add-host

Provision a new host in the HALLway flake.

## Usage

```
/add-host <hostname> [--type nixos-workstation|nixos-vps|home-manager]
```

Type defaults:
- `nixos-workstation` — x86_64-linux NixOS with Hyprland/DOORwayDE (like 2600AD)
- `nixos-vps` — x86_64-linux NixOS minimal server (like HALLpass.space)
- `home-manager` — Standalone Home Manager, non-NixOS (like HelloMoto)

If `--type` is not provided, ask the user to confirm.

Ask the user for:
- **Primary username** (for NixOS types: the main user account; for HM: `home.username`)
- **System architecture** (default: `x86_64-linux`; change to `aarch64-linux` for ARM/Android)
- **Brief description** (for the file header)

## Steps

### 1. Create the directory structure

**NixOS hosts:**
```
hosts/<hostname>/
  configuration.nix       ← from template
  hardware-configuration.nix  ← placeholder with TODO
  secrets.nix             ← from template
  home/<username>.nix     ← from template
```

**Standalone Home Manager:**
```
hosts/<hostname>/
  secrets.nix             ← from template
  home/<username>.nix     ← from template (contains `imports = [ ../secrets.nix ];`)
```

Fill templates from `.claude/skills/add-host/templates/`:
- `nixos-workstation.nix` → `configuration.nix`
- `nixos-vps.nix` → `configuration.nix`
- `secrets-nixos.nix` → `secrets.nix` (NixOS)
- `secrets-hm.nix` → `secrets.nix` (standalone HM)
- `home-user.nix` → `home/<username>.nix`
- `home-manager.nix` → standalone HM home file

Replace all template placeholders:
- `<HOSTNAME>` → the hostname argument
- `<USERNAME>` → the primary username
- `<SYSTEM>` → the architecture (e.g. `x86_64-linux`)
- `<DESCRIPTION>` → the brief description

### 2. Create hardware-configuration.nix placeholder (NixOS only)

```nix
# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<hostname>/hardware-configuration.nix - Hardware config           ║
# ╚════════════════╝
#
# TODO: Replace this with the output of:
#   nixos-generate-config --show-hardware-config
# (run on the target machine, then paste here)
#
{ ... }: { }
```

### 3. Create encrypted secrets.yaml skeleton

Instruct the user to create the initial secrets file:

```bash
nix develop
# Create an empty encrypted file (sops opens editor; add a placeholder comment, save, quit)
sops hosts/<hostname>/secrets.yaml
```

Tell them: Add at minimum a comment `# secrets for <hostname>` on the first line and save. Sops will encrypt it. The file must exist and be valid sops-encrypted YAML before `nix flake check` will pass.

Wait for the user to confirm the file was created before proceeding.

### 4. Register in flake.nix

**NixOS host** — add to `nixosConfigurations` in `flake.nix` following the existing pattern:

```nix
# ─────────────────────────────────────────────────────────────────────────
# <hostname> - <description>
# Activate with: sudo nixos-rebuild switch --flake .#<hostname>
# ─────────────────────────────────────────────────────────────────────────
"<hostname>" = nixpkgs.lib.nixosSystem {
  system = "<SYSTEM>";
  modules = [
    ./hosts/<hostname>/configuration.nix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = false;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.backupFileExtension = "backup";
      home-manager.users.<username> = import ./hosts/<hostname>/home/<username>.nix;
    }
    sops-nix.nixosModules.sops
  ];
};
```

**Standalone HM host** — add to `homeConfigurations`:

```nix
# ─────────────────────────────────────────────────────────────────────────
# <hostname> - <description>
# Activate with: home-manager switch --flake .#<hostname>
# ─────────────────────────────────────────────────────────────────────────
"<hostname>" = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages."<SYSTEM>";
  modules = [
    ./hosts/<hostname>/home/<username>.nix
    sops-nix.homeManagerModules.sops
  ];
};
```

### 5. Add to .sops.yaml

Add a placeholder anchor and creation rule for this host. The actual age public key is unknown until first boot — add it as a TODO:

```yaml
keys:
  # ... existing keys ...
  - &host_<hostname_slug>  # TODO: replace with output of: ssh-keyscan <hostname> | grep ed25519 | ssh-to-age

creation_rules:
  # ... existing rules ...
  - path_regex: hosts/<hostname>/secrets\.yaml$
    key_groups:
      - age:
          - *admin
          - *host_<hostname_slug>   # TODO: uncomment after adding key above
```

Note: `<hostname_slug>` is the hostname lowercased with `.` replaced by `_` (e.g. `HALLpass.space` → `hallpass_space`).

Remind the user: Until the real host key is obtained and the TODO lines are filled in, sops will use admin-key-only encryption. That's fine for initial deployment — run `sops updatekeys` after first boot when the host key is known.

### 6. Validate

```bash
nix flake check
```

If check fails with "file does not exist: secrets.yaml" — ensure step 3 was completed.
If it fails with a Nix evaluation error, inspect the template substitution for typos.

### 7. Next steps

Remind the user:

1. For NixOS hosts: replace `hardware-configuration.nix` with `nixos-generate-config --show-hardware-config` output from the target machine
2. Fill in placeholder values in `configuration.nix` (WireGuard public keys, Syncthing IDs, etc.)
3. After first boot: get host age key with `ssh-keyscan <host> | grep ed25519 | ssh-to-age`, fill `.sops.yaml`, run `sops updatekeys hosts/<hostname>/secrets.yaml`
4. Add actual secrets to `secrets.yaml` via `sops hosts/<hostname>/secrets.yaml`
