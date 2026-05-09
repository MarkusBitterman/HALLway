# HelloMoto

> HALLway host — Android phone (Termux + Nix)

**Architecture**: `aarch64-linux`
**Config type**: Standalone Home Manager (`homeConfigurations."HelloMoto"`)

---

## Table of Contents

- [Quick Start](#quick-start)
- [Role](#role)
- [Installation](#installation)
  - [Standard](#standard)
  - [Full Step-by-Step](#full-step-by-step)
- [How to Contribute](#how-to-contribute)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Already set up?** Rebuild after config changes:

```bash
# On the phone, in Termux:
cd ~/hallway
home-manager switch --flake .#HelloMoto
```

**Fresh setup?** See [Installation](#installation) below.

---

## Role

Mobile device for:
- WireGuard peer (managed by Android WireGuard app, not Nix)
- Syncthing peer (managed by Android Syncthing app, not Nix)
- SSH client to other HALLway hosts

## Configuration Model

- Home Manager config: [home/user.nix](home/user.nix)
- agenix secret mappings: [secrets.nix](secrets.nix)

## Notes

- WireGuard is managed by the Android WireGuard app — not via Nix
- Syncthing is managed by the Android Syncthing app — not via Nix
- There is no system SSH host key on Android; `~/.ssh/id_ed25519` is the agenix identity

---

## Installation

### Standard

This is a standalone Home Manager configuration for Termux. No NixOS install required.

### Full Step-by-Step

#### Prerequisites

1. Install Termux from F-Droid (not Play Store)
2. Bootstrap Nix in Termux (see [nix-on-droid](https://github.com/nix-community/nix-on-droid) or manual Nix install)

#### Step 1: Fill in your username

Run `whoami` in Termux and replace `PHONE_USERNAME` in `hosts/HelloMoto/home/user.nix`.

#### Step 2: Add phone SSH key as agenix recipient

```bash
# On the phone, generate an SSH key if you don't have one:
ssh-keygen -t ed25519

# Convert to age format:
cat ~/.ssh/id_ed25519.pub | ssh-to-age
# → age1xxxx...
```

Paste into `secrets.nix` (repo root) as `hellomoto`, uncomment the variable, add to the `hosts/HelloMoto/secrets/ssh_key_github.age` entry.

Then rekey from 2600AD:

```bash
nix develop
agenix -r -i ~/.ssh/id_hallpass
```

#### Step 3: Create the GitHub SSH secret

```bash
# From 2600AD dev shell (admin-only until phone key is added):
agenix -e hosts/HelloMoto/secrets/ssh_key_github.age -i ~/.ssh/id_hallpass
```

#### Step 4: Replace remaining placeholders

| Placeholder | Location | Value |
|-------------|----------|-------|
| `PHONE_USERNAME` | `home/user.nix` | Output of `whoami` in Termux |
| `DESKTOP_IP_OR_HOSTNAME` | `home/user.nix` | 2600AD LAN IP or WireGuard IP (`10.44.0.2`) |

#### Step 5: Clone and activate

On the phone, in Termux:

```bash
git clone https://github.com/MarkusBitterman/HALLway.git ~/hallway
cd ~/hallway
home-manager switch --flake .#HelloMoto
```

---

## How to Contribute

See [CONTRIBUTING.md](../../CONTRIBUTING.md) in the repository root for:

- Dev environment setup
- Code style guidelines
- Pull request process

---

## Troubleshooting

### home-manager command not found

Ensure Nix is properly installed in Termux and home-manager is available:

```bash
nix-shell -p home-manager
```

Or add home-manager to your Nix profile.

### agenix secrets not decrypting

The phone's `~/.ssh/id_ed25519` must be:
1. Generated on the phone
2. Converted to age format and added to root `secrets.nix`
3. Secrets rekeyed with `agenix -r`

### SSH connection to 2600AD fails

Check that:
- WireGuard is connected (via Android app)
- `DESKTOP_IP_OR_HOSTNAME` is correct in `home/user.nix`
- SSH key is authorized on 2600AD

---

## Related

- 2600AD (desktop): [../2600AD/README.md](../2600AD/README.md)
- Secrets workflow: [../../docs/secrets.md](../../docs/secrets.md)
