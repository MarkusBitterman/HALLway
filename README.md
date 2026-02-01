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

- *a modern device OS* 📲🖥️💻 + *router* 🌐🛜 + *digital wallet* 🫆👛 + *local-first "cloud"* 👟🥅 that treats the public internet 🌐 like *what it often is…* 🤮🦠💉😷

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/) with flakes enabled

### Quick Start

```bash
# Clone the repository
git clone https://github.com/MarkusBitterman/HALLway.git
cd HALLway

# Enter the development shell
nix develop

# Validate the flake
nix flake check
```

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

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before getting started.

### Quick Links

- [Dev Environment Quickstart](CONTRIBUTING.md#dev-environment-quickstart)
- [Working with Copilot](CONTRIBUTING.md#working-with-copilot)
- [Code Style and Formatting](CONTRIBUTING.md#code-style-and-formatting)
