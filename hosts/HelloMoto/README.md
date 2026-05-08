# HelloMoto: Android Phone (Termux + Nix)

**Target**: Android phone running Termux with Nix bootstrapped  
**Role**: WireGuard peer (managed by Android WireGuard app), Syncthing peer, SSH client  
**Config type**: Standalone Home Manager (`homeConfigurations."HelloMoto"`)  
**Architecture**: `aarch64-linux`

---

## Activation

```bash
# On the phone, in Termux — clone the repo and activate:
git clone https://github.com/MarkusBitterman/HALLway.git ~/hallway
cd ~/hallway
home-manager switch --flake .#HelloMoto
```

## Pre-Flight

### 1. Fill in your username

Run `whoami` in Termux and replace `PHONE_USERNAME` in `hosts/HelloMoto/home/user.nix`.

### 2. Add phone SSH key as agenix recipient

```bash
# On the phone:
cat ~/.ssh/id_ed25519.pub | ssh-to-age
# → age1xxxx...
```

Paste into `secrets.nix` (repo root) as `hellomoto`, uncomment the variable,
add to the `hosts/HelloMoto/secrets/ssh_key_github.age` entry, then rekey from 2600AD:

```bash
agenix -r -i ~/.ssh/id_hallpass
```

### 3. Create the GitHub SSH secret

```bash
# From 2600AD dev shell (admin-only until phone key is added):
agenix -e hosts/HelloMoto/secrets/ssh_key_github.age -i ~/.ssh/id_hallpass
```

### 4. Replace remaining placeholders

| Placeholder | Location | Value |
|-------------|----------|-------|
| `PHONE_USERNAME` | `home/user.nix` | Output of `whoami` in Termux |
| `DESKTOP_IP_OR_HOSTNAME` | `home/user.nix` | 2600AD LAN IP or WireGuard IP (`10.44.0.2`) |

## Notes

- WireGuard is managed by the Android WireGuard app — not via Nix
- Syncthing is not in this config (phone uses the Android Syncthing app)
- There is no system SSH host key on Android; `~/.ssh/id_ed25519` is the agenix identity
