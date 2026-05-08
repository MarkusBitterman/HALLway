# HALLway

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Project Documentation](#project-documentation)
- [Contributing](#contributing)

## Overview

**the HALLway OS** 🌍🫆🏘️👛🔏; `HALLway` is an operating system stack — and a whole way of doing computing — built around one stubborn, calming idea:

> **Your digital life should live on your hardware, under your rules — by default.** 🫱🏼‍🫲🏿🔏🧠

Not "privacy theater." Not paranoia. Just _practical_ **peace of mind**.

- _a modern device OS_ 📲🖥️💻 + _router_ 🌐🛜 + _digital wallet_ 🫆👛 + _local-first "cloud"_ 👟🥅 that treats the public internet 🌐 like _what it often is…_ 🤮🦠💉😷

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/) with flakes enabled

### Quick Start

```bash
# Clone the repository
git clone https://github.com/MarkusBitterman/HALLway.git
cd HALLway

# Option 1: Enter the development shell (nix-shell)
nix-shell

# Option 2: Enter the development shell (flakes)
nix develop

# Validate the flake
nix flake check

# Build the system (2600AD example)
nix build .#nixosConfigurations.2600AD.config.system.build.toplevel
```

### VS Code Integration

HALLway includes comprehensive VS Code integration:

**Quick Tasks** (Ctrl+Shift+P → "Tasks: Run Task"):

- **✅ Verify** (Ctrl+Shift+T) — Validate flake syntax with `nix flake check`
- **🧑‍🔬 Test All** — Flake check + system eval + home-manager eval
- **🛠️ Build** — Build system closure without activating
- **⚡ Switch** (Ctrl+Shift+B) — `nixos-rebuild switch` to activate changes
- **✨ Format** — Format all `.nix` files with `nixfmt`
- **🔄 Update** — Update all flake inputs
- **🖴 Disk Space** — ZFS pool, nix store, and memory status
- **🗑️ GC** — Garbage collect old generations and unused store paths
- **🗑️ Clean** — Remove build results and logs

See [`.vscode/tasks.json`](.vscode/tasks.json) for all available tasks.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed setup instructions.

## Project Documentation

- [HALLway Project Bible](HALLway%20Project%20Bible.md) — Comprehensive project vision and details
- [Contributing Guide](CONTRIBUTING.md) — How to contribute to HALLway
- [Committing Guide](COMMITTING.md) — How to commit changes to the repository
- [Development Tools](docs/dev-tools.md) — Tools and workflows for development

### Host Documentation

- **2600AD** (Atari VCS 800) — First reference implementation (v0.0.1)
  - [Installation Guide](hosts/2600AD/INSTALLATION.md) — Two-stage USB-bridged installation with ZFS on LUKS
  - [Overview](hosts/2600AD/README.md) — Host-specific configuration details

---

## User and Security Model

HALLway no longer uses the old `roles.users` module.

Current model:

- `users.users.<name>` in host configuration handles account and group policy.
- Home Manager (`hosts/<host>/home/<user>.nix`) handles user package sets and user-space configuration.
- agenix handles secret material (`hosts/<host>/secrets.nix` + encrypted `.age` files).
- AppArmor is enabled at the host level as the active MAC layer on this channel.

### Current Hosts

- 2600AD (Atari VCS 800): workstation/gaming node
- HALLpass.space (minimal VPS): WireGuard + Syncthing introducer node

For host details, use the host docs:

- [hosts/2600AD/README.md](hosts/2600AD/README.md)
- [hosts/HALLpass.space/README.md](hosts/HALLpass.space/README.md)

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before getting started.

### Quick Links

- [Dev Environment Quickstart](CONTRIBUTING.md#dev-environment-quickstart)
- [Working with Claude Code](CONTRIBUTING.md#working-with-claude-code)
- [Code Style and Formatting](CONTRIBUTING.md#code-style-and-formatting)
