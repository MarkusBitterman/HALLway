# HALLway Documentation Map 🗺️

Quick reference guide to find the documentation you need.

## 🎯 I Want To...

### Get Started with HALLway
- **Understand the vision** → [HALLway Project Bible](../HALLway%20Project%20Bible.md)
- **See an overview** → [README.md](../README.md)
- **Install HALLway** → [INSTALLATION.md](../INSTALLATION.md) (generic) or [hosts/2600AD/INSTALLATION.md](../hosts/2600AD/INSTALLATION.md) (Atari VCS 800)

### Understand the System
- **Learn the architecture** → [Architecture Guide](ARCHITECTURE.md)
- **Understand user management** → [README: Role-Based Packages](../README.md#user-management-with-role-based-packages)
- **See available package groups** → [README: Available Package Groups](../README.md#available-package-groups)

### Install HALLway
- **Generic installation guide** → [INSTALLATION.md](../INSTALLATION.md)
- **Atari VCS 800 (2600AD) installation** → [hosts/2600AD/INSTALLATION.md](../hosts/2600AD/INSTALLATION.md)
- **Post-installation steps** → [hosts/2600AD/INSTALLATION.md: What's Next](../hosts/2600AD/INSTALLATION.md#whats-next-after-installation)

### Develop & Contribute
- **Set up dev environment** → [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Learn development tools** → [Development Tools](dev-tools.md)
- **Use VS Code tasks** → [VS Code Tasks](VSCODE_TASKS.md)
- **Commit changes** → [COMMITTING.md](../COMMITTING.md)

### Troubleshoot Issues
- **Find solutions** → [Troubleshooting Guide](TROUBLESHOOTING.md)
- **Installation issues** → [Troubleshooting: Installation](TROUBLESHOOTING.md#installation-issues)
- **Boot/LUKS issues** → [Troubleshooting: Boot & LUKS](TROUBLESHOOTING.md#boot--luks-issues)
- **Package/build issues** → [Troubleshooting: Package & Build](TROUBLESHOOTING.md#package--build-issues)

### Learn About Specific Topics
- **ZFS configuration** → [Architecture: ZFS](ARCHITECTURE.md#zfs)
- **LUKS encryption** → [Architecture: LUKS](ARCHITECTURE.md#luks)
- **Home Manager** → [Architecture: Home Manager](ARCHITECTURE.md#home-manager)
- **Secrets management** → [Architecture: agenix](ARCHITECTURE.md#agenix)

---

## 📚 Documentation by Category

### Core Documentation
| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](../README.md) | Project overview, user management | All users |
| [HALLway Project Bible](../HALLway%20Project%20Bible.md) | Vision, philosophy, future plans | Curious users, contributors |
| [CHANGELOG.md](../CHANGELOG.md) | Version history, recent changes | All users |

### Installation Guides
| Document | Purpose | Audience |
|----------|---------|----------|
| [INSTALLATION.md](../INSTALLATION.md) | Generic installation template | New hardware installations |
| [hosts/2600AD/INSTALLATION.md](../hosts/2600AD/INSTALLATION.md) | Atari VCS 800 specific installation | 2600AD users |
| [hosts/2600AD/README.md](../hosts/2600AD/README.md) | 2600AD configuration details | 2600AD users |

### Development Documentation
| Document | Purpose | Audience |
|----------|---------|----------|
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Contribution guidelines | Contributors |
| [COMMITTING.md](../COMMITTING.md) | Git workflow and commit format | Contributors |
| [Development Tools](dev-tools.md) | Nix dev environment | Developers |
| [VS Code Tasks](VSCODE_TASKS.md) | VS Code task reference | VS Code users |
| [Architecture Guide](ARCHITECTURE.md) | System architecture | Developers, contributors |

### Reference Documentation
| Document | Purpose | Audience |
|----------|---------|----------|
| [Troubleshooting Guide](TROUBLESHOOTING.md) | Solutions to common issues | All users |
| [Architecture Guide](ARCHITECTURE.md) | Repository organization | Developers |

---

## 🔍 Documentation by File Type

### Markdown Files (*.md)

**Root Level**:
- `README.md` - Main entry point
- `HALLway Project Bible.md` - Vision document
- `INSTALLATION.md` - Generic installation guide
- `CONTRIBUTING.md` - Contribution guidelines
- `COMMITTING.md` - Git workflow
- `CHANGELOG.md` - Version history

**docs/ Directory**:
- `docs/ARCHITECTURE.md` - Architecture and file structure
- `docs/TROUBLESHOOTING.md` - Troubleshooting index
- `docs/VSCODE_TASKS.md` - VS Code tasks reference
- `docs/dev-tools.md` - Development tools guide
- `docs/DOCUMENTATION_MAP.md` - This file

**hosts/2600AD/ Directory**:
- `hosts/2600AD/INSTALLATION.md` - 2600AD installation guide
- `hosts/2600AD/README.md` - 2600AD configuration overview

### Configuration Files

**Nix**:
- `flake.nix` - Main flake definition
- `flake.lock` - Dependency lock file
- `shell.nix` - Development shell
- `modules/userRoles.nix` - Role-based user management module
- `hosts/2600AD/configuration.nix` - System configuration
- `hosts/2600AD/hardware-configuration.nix` - Hardware-specific config
- `hosts/2600AD/home/*.nix` - Home Manager configs

**VS Code**:
- `.vscode/tasks.json` - Task definitions (see [VS Code Tasks](VSCODE_TASKS.md))
- `.vscode/settings.json` - Workspace settings
- `.vscode/extensions.json` - Recommended extensions

**Git**:
- `.gitignore` - Git exclusions
- `.editorconfig` - Editor formatting rules

---

## 🆘 Quick Help

### "I'm stuck during installation"
→ [Troubleshooting: Installation Issues](TROUBLESHOOTING.md#installation-issues)

### "I don't know where to start"
→ [README](../README.md) → [Project Bible](../HALLway%20Project%20Bible.md) → [Installation](../INSTALLATION.md)

### "I want to contribute"
→ [CONTRIBUTING.md](../CONTRIBUTING.md) → [Architecture](ARCHITECTURE.md) → [Dev Tools](dev-tools.md)

### "I need to understand how it works"
→ [Architecture Guide](ARCHITECTURE.md) → [README: User Management](../README.md#user-management-with-role-based-packages)

### "Something broke"
→ [Troubleshooting Guide](TROUBLESHOOTING.md)

### "I want to use VS Code"
→ [VS Code Tasks](VSCODE_TASKS.md) → [Dev Tools](dev-tools.md)

---

## 📅 Documentation Maintenance

### Last Major Update
- **Date**: 2026-02-01
- **Changes**: Added troubleshooting guide, VS Code tasks docs, architecture guide
- **PR**: [Documentation Review & Reconciliation](#)

### Contributing to Documentation

Found an error? Want to improve docs? See [CONTRIBUTING.md](../CONTRIBUTING.md).

**Tips for doc contributions**:
- Keep language clear and concise
- Use examples where helpful
- Link to related documentation
- Update "Last Updated" dates when making significant changes
- Add entries to CHANGELOG.md for major doc changes

---

## 🔗 External Resources

### NixOS & Nix
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Search](https://search.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)

### Home Manager
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)

### Technologies
- [ZFS Documentation](https://openzfs.org/wiki/Main_Page)
- [LUKS/dm-crypt](https://wiki.archlinux.org/title/Dm-crypt)
- [agenix GitHub](https://github.com/ryantm/agenix)

---

**Welcome to HALLway!** 🏠
