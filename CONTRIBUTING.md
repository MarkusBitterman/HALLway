# Contributing to HALLway

Thank you for your interest in contributing to HALLway! This guide will help you get started.

## Table of Contents

- [Dev Environment Quickstart](#dev-environment-quickstart)
- [Working with Claude Code](#working-with-claude-code)
- [Code Style and Formatting](#code-style-and-formatting)
- [Committing Changes](#committing-changes)
- [Pull Request Process](#pull-request-process)

---

## Dev Environment Quickstart

HALLway uses [Nix](https://nixos.org/) for reproducible development environments.

### Prerequisites

1. **Install Nix** (if you haven't already):

   ```bash
   # Review the installation script at https://nixos.org/nix/install before running
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

   See the [official Nix installation guide](https://nixos.org/download.html) for more options.

2. **Enable flakes** (add to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`):

   ```nix
   experimental-features = nix-command flakes
   ```

### Enter the Development Shell

```bash
# Clone the repository
git clone https://github.com/MarkusBitterman/HALLway.git
cd HALLway

# Enter the dev shell (this downloads all required tools)
nix develop
```

That's it! You now have all the development tools available.

### Available Commands

Once in the dev shell:

| Command | Description |
|---------|-------------|
| `nix flake check` | Validate the flake and run checks |
| `nix fmt` | Format all Nix files |

### VS Code Integration

This repository includes VS Code settings for optimal development:

1. Install the [recommended extensions](.vscode/extensions.json) when prompted
2. Settings are automatically applied from [.vscode/settings.json](.vscode/settings.json)
3. Use **Tasks: Run Task** (Ctrl/Cmd+Shift+P) to access common commands

### Using direnv (Optional)

For automatic shell activation when you `cd` into the project:

1. Install direnv: <https://direnv.net/docs/installation.html>
2. Create `.envrc` in the project root:

   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```

---

## Working with Claude Code

HALLway uses **Claude Code** (Anthropic) as a **power tool, not an authority**.

### Expected Usage

- **Drafting**: Use Claude to accelerate writing boilerplate, configs, and documentation
- **Exploration**: Ask Claude for ideas, patterns, or to explain unfamiliar NixOS/Nix code
- **Acceleration**: Let Claude help with repetitive tasks and cross-file edits

### Required Review Posture

**Humans verify everything.** AI suggestions must be:

1. **Reviewed** — Read and understand every change before accepting
2. **Tested** — Run `nix flake check` and `nix fmt` to verify correctness
3. **Audited** — Check for security issues, especially in:
   - Cryptographic code and sops secrets
   - Network configuration (WireGuard, firewall rules)
   - Permission handling (`mode`, `owner`, `group` on secrets)

### Prompt Hygiene

**Never include in prompts:**

- Private keys, passphrases, or `secrets.yaml` contents
- API tokens or credentials
- Real WireGuard private keys
- Internal infrastructure IP addresses beyond what is already in this repo

---

## Code Style and Formatting

### Automated Formatting

- **Nix files**: Formatted with `nixfmt` (RFC 166 style)
- **All files**: Follow [.editorconfig](.editorconfig) settings

Run formatting before committing:

```bash
nix fmt
```

### EditorConfig

The repository includes an [.editorconfig](.editorconfig) file that most editors will automatically respect. Key settings:

- UTF-8 encoding
- LF line endings
- 2-space indentation
- Trailing whitespace trimmed (except in Markdown)

---

## Committing Changes

### Commit Message Format

```
<type>: <description>

<body (optional)>
```

### Types

| Type | Use for |
|------|---------|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `refactor:` | Code reorganization without behavior change |
| `chore:` | Build, dependencies, or tooling |
| `v0.x.x:` | Version bump (e.g., "v0.0.1: Description") |

### Examples

```bash
# New host implementation
git commit -m "v0.0.1: 2600AD - Atari VCS 800 initial working build"

# Feature addition
git commit -m "feat: Add TPM2 auto-unlock support for LUKS partitions"

# Bug fix
git commit -m "fix: Resolve ZFS module loading issue in Stage 1 installation"

# Documentation
git commit -m "docs: Add two-stage installation guide with space optimization"
```

### Before Committing

1. **Format code**:
   ```bash
   nix fmt
   ```

2. **Validate flake**:
   ```bash
   nix flake check
   ```

3. **Review changes**:
   ```bash
   git status
   git diff --staged
   ```

### Git Workflow

```bash
# Stage changes
git add -A

# Commit
git commit -m "type: description"

# Push
git push origin main
```

### Syncing with Remote

```bash
# Fetch latest
git fetch origin

# Pull changes
git pull origin main

# See what's different
git log HEAD..origin/main
```

---

## Pull Request Process

1. **Fork** the repository and create a feature branch
2. **Make changes** following the code style guidelines
3. **Test** your changes locally:

   ```bash
   nix flake check
   nix fmt
   ```

4. **Commit** with clear, descriptive messages (see above)
5. **Open a PR** with:
   - Clear description of what changed and why
   - Reference to any related issues
6. **Address review feedback** promptly

---

## Troubleshooting

### "Permission denied (publickey)"

If using IDE-based authentication, this is handled automatically when you push.

### "Everything up-to-date"

All your commits are already pushed. Run `git log` to see history.

### "Dirty working tree"

You have uncommitted changes:

```bash
git status
git add -A
git commit -m "your message"
```

---

Questions? Open an issue or start a discussion.
