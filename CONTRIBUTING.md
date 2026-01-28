# Contributing to HALLway 🏡🔐

Thank you for your interest in contributing to HALLway! This guide will help you get started.

## Table of Contents

- [Dev Environment Quickstart](#dev-environment-quickstart)
- [Working with Copilot](#working-with-copilot)
- [Code Style and Formatting](#code-style-and-formatting)
- [Pull Request Process](#pull-request-process)

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
   ```
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

1. Install direnv: https://direnv.net/docs/installation.html
2. Create `.envrc` in the project root:
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```

## Working with Copilot

HALLway uses GitHub Copilot as a **power tool, not an authority** 🛠️

### Expected Usage

- **Drafting**: Use Copilot to accelerate writing boilerplate, configs, and documentation
- **Exploration**: Ask Copilot for ideas, patterns, or to explain unfamiliar code
- **Acceleration**: Let Copilot help with repetitive tasks

### Required Review Posture

**Humans verify everything.** Copilot suggestions must be:

1. ✅ **Reviewed** - Read and understand every suggestion before accepting
2. ✅ **Tested** - Run builds and tests to verify correctness
3. ✅ **Audited** - Check for security issues, especially in:
   - Cryptographic code
   - Network configuration
   - Permission handling
   - Input validation

### Prompt Hygiene 🧹

**Never include in prompts or code:**

- 🚫 Private keys or secrets
- 🚫 API tokens or credentials
- 🚫 Personal identifying information
- 🚫 Internal infrastructure details
- 🚫 Proprietary algorithms (unless intentionally open-sourcing)

### Before Opening PRs

Always run these checks locally:

```bash
# Enter dev shell (if not already)
nix develop

# Validate the flake
nix flake check

# Format code
nix fmt
```

## Code Style and Formatting

### Automated Formatting

- **Nix files**: Formatted with `nixfmt` (nixfmt-rfc-style, RFC 166 style)
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

## Pull Request Process

1. **Fork** the repository and create a feature branch
2. **Make changes** following the code style guidelines
3. **Test** your changes locally:
   ```bash
   nix flake check
   nix fmt
   ```
4. **Commit** with clear, descriptive messages
5. **Open a PR** with:
   - Clear description of what changed and why
   - Reference to any related issues
6. **Address review feedback** promptly

### Commit Message Guidelines

- Use present tense ("Add feature" not "Added feature")
- Keep the first line under 72 characters
- Reference issues when applicable (`Fixes #123`)

---

Questions? Open an issue or start a discussion. We're building this hallway together! 🚪✨
