# Development Tools

This document describes the development tools and workflows used in HALLway.

## Nix Development Environment

HALLway uses Nix flakes for reproducible development environments.

### Why Nix?

> Nix gives us the boring superpower that makes everything else possible:
>
> - **Reproducible builds** (no "works on my machine" ghost stories)
> - **Declarative configs** (systems are described, not accidentally assembled)
> - Easy to audit "what changed" between builds
>
> — HALLway Project Bible

### Tools in the Dev Shell

| Tool | Purpose |
|------|---------|
| `git` | Version control (Mercurial migration planned) |
| `nixd` | Nix language server for editor integration |
| `nixfmt` | Nix code formatter (RFC 166 style) |
| `direnv` | Automatic environment activation |
| `nix-direnv` | Fast direnv integration for Nix |
| `sops` | Encrypted secrets management (YAML + age) |
| `age` | Age encryption primitives |
| `ssh-to-age` | Convert SSH ed25519 public keys to age recipient format |

### Common Commands

```bash
# Enter the development shell
nix develop

# Validate the flake
nix flake check

# Format Nix files
nix fmt

# Update flake inputs
nix flake update

# Edit secrets
sops hosts/2600AD/secrets.yaml
```

## Editor Setup

### VS Code

Recommended extensions are listed in [.vscode/extensions.json](../.vscode/extensions.json):

- **Nix IDE** (`jnoortheen.nix-ide`) - Nix language support
- **EditorConfig** (`editorconfig.editorconfig`) - Consistent formatting
- **Claude Code** - AI assistance (replaces GitHub Copilot)
- **direnv** (`mkhl.direnv`) - Automatic dev shell activation

### Other Editors

Any editor that supports:

- EditorConfig (for consistent formatting)
- LSP (for Nix language server integration)

Should work well with this project.

## AI-Assisted Development

### Claude Code

HALLway uses **Claude Code** (Anthropic) as the AI development assistant. Use it as a **power tool, not an authority**:

- Use for drafting configs, exploring options, understanding unfamiliar NixOS patterns
- Always run `nix flake check` after AI-suggested changes
- Review all changes — especially cryptographic code, network config, and sops secrets
- Never include secrets, passphrases, or private keys in prompts
- Don't blindly accept suggestions for security-sensitive config

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

## Continuous Integration

*(Coming soon)*

Future CI will include:

- Nix flake checks
- Formatting verification
- Security scanning

## Code Quality

### Formatting

All code is automatically formatted:

- **Nix**: `nixfmt` (RFC 166 style)
- **General**: EditorConfig settings

Run `nix fmt` before committing.

### Linting

*(Linters will be added as the codebase grows)*

---

## Troubleshooting

### "Nix command not found"

Make sure Nix is installed and flakes are enabled:

```bash
# Check Nix installation
nix --version

# Enable flakes (add to ~/.config/nix/nix.conf)
# Check if flakes are already enabled
grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null || \
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "Flake check fails"

```bash
# Update flake inputs
nix flake update

# Try again
nix flake check
```

### "nixd not working in VS Code"

1. Make sure you're in the dev shell (`nix develop`)
2. Restart VS Code
3. Check that Nix IDE extension is installed

### "Pre-switch check 'switchInhibitors' failed"

When `nixos-rebuild switch` reports changes to critical system components, it will refuse to apply them live:

```
There are changes to critical components of the system:

dbus-implementation : dbus -> broker

Switching into this system is not recommended.
```

**What's happening**: Components like D-Bus, systemd, or the kernel are fundamental to the running system. Swapping them while running can cause session instability or crash services.

**Solution**: Use `nixos-rebuild boot` followed by a reboot instead of `switch`:

```bash
sudo nixos-rebuild boot --flake .#2600AD
sudo reboot
```

The `boot` command installs the new configuration as the default boot entry without activating it. After reboot, the system starts fresh with the new components.

**Override (not recommended)**: If you really need to switch live, set `NIXOS_NO_CHECK=1`:

```bash
sudo NIXOS_NO_CHECK=1 nixos-rebuild switch --flake .#2600AD
```

This bypasses the safety check but may cause instability.

### "Failed to get data key" (sops)

Your admin key can't decrypt the secrets file. Check:

1. `~/.config/sops/age/keys.txt` exists
2. Contains a valid age private key (starts with `AGE-SECRET-KEY-`)
3. No extra lines like `Public key:` at the top
4. Your public key is in `.sops.yaml` for the file's `creation_rules`

**Solution**: Fix the key file format:

```bash
# Check current format
cat ~/.config/sops/age/keys.txt

# Should look like:
# # created: 2026-05-18T16:43:31-05:00
# # public key: age1xxxxx...
# AGE-SECRET-KEY-xxxxxx
```

### "no identity matched any of the recipients"

The host key isn't in the recipient list. Rekey the secrets:

```bash
sops updatekeys hosts/<host>/secrets.yaml
```

---

For more help, see [CONTRIBUTING.md](../CONTRIBUTING.md) or open an issue.
