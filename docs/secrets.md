# HALLway Secrets Management

HALLway uses [agenix](https://github.com/ryantm/agenix) to manage secrets as
`age`-encrypted files committed to the repository. No plaintext secrets ever
touch version control.

---

## The Two-Phase Model

| Phase | Who triggers it | What happens |
|-------|----------------|--------------|
| **Create / Edit** | You, manually, once | `agenix -e <file>` opens `$EDITOR` with the decrypted content; on save agenix re-encrypts for all recipients listed in `secrets.nix`. |
| **Deploy** | `nixos-rebuild switch`, automatically | The agenix NixOS module decrypts each `.age` file and places it at the path / owner / mode declared in `hosts/<host>/secrets.nix`. |

> `agenix -e` is **not** run by the build system. You run it exactly once per
> secret (or again whenever you need to rotate a value). Every subsequent
> `nixos-rebuild` just decrypts the existing file — no manual step needed.

---

## The Two `secrets.nix` Files

There are **two completely different files** both called `secrets.nix`. Do not
confuse them:

| File | Purpose | Used by |
| ---- | ------- | ------- |
| `secrets.nix` (repo root) | agenix CLI rules — maps `.age` files to recipient keys | `agenix -e` / `agenix -r` CLI |
| `hosts/<host>/secrets.nix` | NixOS module — declares runtime paths, owners, modes | `nixos-rebuild switch` |

Both must be committed to git. The root file controls encryption; the host
files control decryption at deploy time.

---

## Setup: Deriving Age Recipient Keys

Before you can create or edit secrets, fill in the recipient key values in
the root `secrets.nix` rules file. Use `ssh-to-age` to convert ed25519 SSH
public keys to age format:

```bash
# 1. Admin key (bittermang — run on 2600AD)
#    This system uses id_hallpass (not the default id_ed25519)
cat ~/.ssh/id_hallpass.pub | ssh-to-age
# → age1xxxx...  paste as `bittermang` in secrets.nix

# 2. 2600AD system SSH host key
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
# → age1xxxx...  paste as `host2600AD` in secrets.nix

# 3. HALLpass.space system host key (run after first VPS boot)
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# → age1xxxx...  paste as `hallpass` in secrets.nix
#    Then uncomment the hallpass variable and rekey (see below)
```

Each 2600AD secret is encrypted for **two** recipients: the admin key (so you
can edit from your workstation) and the target host key (so `nixos-rebuild`
can decrypt at activation time).

> **Current state**: HALLpass.space secrets are encrypted for the admin key
> only — the VPS host key is not yet known. After first VPS boot, obtain the
> host key, uncomment `hallpass` in `secrets.nix`, and rekey (see
> [Rekeying after VPS provisioning](#rekeying-after-vps-provisioning)).

---

## Secrets Reference

### 2600AD

| Secret name | File | What it is | How to generate the plaintext |
| ------------- | ------ | ------------ | ------------------------------- |
| `ssh_key_github` | `hosts/2600AD/secrets/ssh_key_github.age` | SSH private key for GitHub | `ssh-keygen -t ed25519 -C "bittermang@2600AD"` → paste private key |
| `ssh_key_hobbs` | `hosts/2600AD/secrets/ssh_key_hobbs.age` | SSH private key for hobbs server | `ssh-keygen -t ed25519 -C "bittermang@hobbs"` → paste private key |
| `ssh_key_hallpass` | `hosts/2600AD/secrets/ssh_key_hallpass.age` | SSH private key for hallpass server | `ssh-keygen -t ed25519 -C "bittermang@hallpass"` → paste private key |
| `github_token` | `hosts/2600AD/secrets/github_token.age` | GitHub personal access token | [GitHub → Settings → Developer settings → PAT](https://github.com/settings/tokens) |
| `gpg_key` | `hosts/2600AD/secrets/gpg_key.age` | GPG private key (armored export) | `gpg --export-secret-keys --armor <KEY_ID>` |
| `wg-2600ad-privatekey` | `hosts/2600AD/secrets/wg-2600ad-privatekey.age` | WireGuard client private key | `wg genkey` (see WireGuard section below) |
| `syncthing-gui-pass` | `hosts/2600AD/secrets/syncthing-gui-pass.age` | Syncthing GUI password (plaintext) | Choose a strong password |

### HALLpass.space

| Secret name | File | What it is | How to generate the plaintext |
| ------------- | ------ | ------------ | ------------------------------- |
| `ssh_key_github` | `hosts/HALLpass.space/secrets/ssh_key_github.age` | SSH private key for GitHub | `ssh-keygen -t ed25519 -C "matt@hallpass.space"` → paste private key |
| `wg-hallpass-privatekey` | `hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age` | WireGuard server private key | `wg genkey` (see WireGuard section below) |
| `syncthing-gui-pass` | `hosts/HALLpass.space/secrets/syncthing-gui-pass.age` | Syncthing GUI password (plaintext) | Choose a strong password |

---

## WireGuard Keys: Private vs. Public

WireGuard **private keys** are secrets — they live in agenix `.age` files.
WireGuard **public keys** are *not* secrets — they are plain string literals
in the Nix configuration.

The placeholders `HALLPASS_WG_PUBLIC_KEY`, `DESKTOP_WG_PUBLIC_KEY`, and
`PHONE_WG_PUBLIC_KEY` in the configuration files are just regular Nix string
values that need to be replaced after key generation. No agenix involvement.

### Generating the WireGuard keypairs

```bash
# ── HALLpass.space server keypair ───────────────────────────────────────────
wg genkey | tee /tmp/wg-hallpass.key | wg pubkey > /tmp/wg-hallpass.pub

# Encrypt private key into agenix (opens $EDITOR; paste the key, save & quit)
agenix -e hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age
# (or: wg genkey | agenix -e ... — pipe is fine if your editor reads stdin)

# Copy the public key to paste into 2600AD's config:
cat /tmp/wg-hallpass.pub
# → Replace HALLPASS_WG_PUBLIC_KEY in hosts/2600AD/configuration.nix

# ── 2600AD client keypair ────────────────────────────────────────────────────
wg genkey | tee /tmp/wg-2600ad.key | wg pubkey > /tmp/wg-2600ad.pub

agenix -e hosts/2600AD/secrets/wg-2600ad-privatekey.age

cat /tmp/wg-2600ad.pub
# → Replace DESKTOP_WG_PUBLIC_KEY in hosts/HALLpass.space/configuration.nix

# ── Phone keypair ────────────────────────────────────────────────────────────
# Generate on the phone via its WireGuard app, or:
wg genkey | tee /tmp/wg-phone.key | wg pubkey > /tmp/wg-phone.pub

cat /tmp/wg-phone.pub
# → Replace PHONE_WG_PUBLIC_KEY in hosts/HALLpass.space/configuration.nix
# (Phone private key stays on the device; no agenix needed)
```

Clean up temp files after use:

```bash
rm -f /tmp/wg-*.key /tmp/wg-*.pub
```

---

## Syncthing Device IDs (Not Secrets)

Syncthing device IDs are auto-generated by Syncthing on first launch. They
are not secret — they appear in the Syncthing UI and logs. Obtain them after
first deployment and replace the placeholders in `hosts/2600AD/configuration.nix`.

```bash
# On HALLpass.space after first deploy:
syncthing cli show system | jq -r .myID
# → Replace HALLPASS_SYNCTHING_DEVICE_ID

# The stdiscosrv (discovery) and strelaysrv (relay) use the Syncthing cert
# for their IDs; get them from their startup logs:
journalctl -u syncthing-discovery | grep -i deviceid | tail -1
journalctl -u syncthing.service   | grep -i relay    | tail -1
# → Replace DISCOVERY_SERVER_ID and RELAY_SERVER_ID

# On your phone: Settings → Advanced → Device ID
# → Replace PHONE_SYNCTHING_DEVICE_ID
```

---

## First-Time Creation Workflow

```bash
# Step 0: enter the dev shell
#   This automatically sets:
#     RULES="$PWD/secrets.nix"  (agenix rules file location)
#     EDITOR="code --wait"      (opens secrets in VS Code)
#   The `agenix` command here is a wrapper around nix run github:ryantm/agenix
#   (NOT the incompatible `agenix-cli` package — see Pitfalls below)
nix-shell   # or: nix develop

# Step 1: fill in secrets.nix recipient keys (see Setup section above)
$EDITOR secrets.nix

# Step 2: create each secret
#   - `agenix -e` opens $EDITOR with the decrypted temp file
#   - Paste the real value, save & close the editor tab
#   - On close, agenix re-encrypts and writes the .age file
#   - Always pass -i to identify which SSH key to decrypt with
agenix -e hosts/2600AD/secrets/ssh_key_github.age     -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/ssh_key_hobbs.age      -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/ssh_key_hallpass.age   -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/github_token.age       -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/gpg_key.age            -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/wg-2600ad-privatekey.age -i ~/.ssh/id_hallpass
agenix -e hosts/2600AD/secrets/syncthing-gui-pass.age -i ~/.ssh/id_hallpass

agenix -e hosts/HALLpass.space/secrets/ssh_key_github.age       -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age -i ~/.ssh/id_hallpass
agenix -e hosts/HALLpass.space/secrets/syncthing-gui-pass.age   -i ~/.ssh/id_hallpass

# Step 3: fill in public-key / device-ID placeholders (see sections above)
$EDITOR hosts/2600AD/configuration.nix
$EDITOR hosts/HALLpass.space/configuration.nix

# Step 4: deploy
sudo nixos-rebuild switch --flake .#2600AD
sudo nixos-rebuild switch --flake .#HALLpass.space   # run on the VPS
```

---

## Editing an Existing Secret

```bash
agenix -e hosts/<host>/secrets/<name>.age -i ~/.ssh/id_hallpass
```

agenix decrypts the current value into a temp file, opens `$EDITOR`, and
re-encrypts on save. Run `nixos-rebuild switch` afterwards — agenix decrypts
automatically during activation. No other manual steps needed.

### Where these paths are consumed

- 2600AD SSH identities are consumed directly via
  `osConfig.age.secrets.<name>.path` in Home Manager:
  - `ssh_key_github`
  - `ssh_key_hobbs`
  - `ssh_key_hallpass`
- 2600AD runtime env vars:
  - `GITHUB_TOKEN_FILE = osConfig.age.secrets."github_token".path`
  - `GPG_PRIVATE_KEY_FILE = osConfig.age.secrets."gpg_key".path`
- WireGuard/Syncthing use these NixOS options:
  - `networking.wireguard.interfaces.<if>.privateKeyFile = config.age.secrets."...".path`
  - `services.syncthing.guiPasswordFile = config.age.secrets."...".path`

---

## Rotating Recipients (e.g., new SSH key)

1. Update the age public key(s) in the root `secrets.nix`.
2. Rekey all secrets so new recipients are included:

   ```bash
   # From the dev shell (RULES already set):
   agenix -r -i ~/.ssh/id_hallpass
   # agenix -r rekeyes ALL .age files listed in secrets.nix at once.
   # There is no per-file argument for -r.
   ```

3. Commit the updated `.age` files.

### Rekeying after VPS provisioning

Once HALLpass.space is deployed, add its host key so the VPS can decrypt its
own secrets at boot:

```bash
# 1. Get the VPS host key
ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
# → age1xxxx...

# 2. Fill it in:
#    Uncomment and set `hallpass = "age1xxxx..."` in secrets.nix
#    Update the three HALLpass.space entries to include both `bittermang` and `hallpass`
$EDITOR secrets.nix

# 3. Rekey (re-encrypts all files with the new recipient set)
agenix -r -i ~/.ssh/id_hallpass

# 4. Commit
git add secrets.nix hosts/HALLpass.space/secrets/
git commit -m "feat: add HALLpass.space host key recipient and rekey"
```

---

## Pitfalls & Troubleshooting

Hard-won lessons from setting up agenix on this repo. Read before touching
any `.age` files.

### ❌ Wrong `agenix` binary

`nixpkgs` ships a package called `agenix-cli` — a Rust reimplementation with
incompatible behavior. It fails silently or errors with `"Failed to find
config root"`. The official tool is [ryantm/agenix](https://github.com/ryantm/agenix).

The dev shell (`nix-shell` / `nix develop`) provides a wrapper function:

```bash
agenix() { nix run github:ryantm/agenix -- "$@"; }
```

Do **not** install `agenix-cli` directly. If `agenix --version` reports
`agenix-cli 0.x.x`, you're using the wrong one — exit and re-enter the dev
shell.

---

### ❌ Existing `.age` file blocks first encryption

agenix always tries to **decrypt** the target file before re-encrypting.
This means:

- An empty file → `failed to read header: EOF`
- A file with only comments → `unexpected intro sequence`
- A file with an age *public key* pasted into it → decryption attempt, wrong format

**Rule**: before creating a secret for the first time, the `.age` file must
**not exist at all**. Delete it first:

```bash
rm -f hosts/<host>/secrets/<name>.age
agenix -e hosts/<host>/secrets/<name>.age -i ~/.ssh/id_hallpass
```

For batch seeding placeholder content (e.g., to satisfy the build before you
have real values), pipe via stdin:

```bash
# File must not exist
rm -f hosts/<host>/secrets/<name>.age
echo "PLACEHOLDER" | agenix -e hosts/<host>/secrets/<name>.age -i ~/.ssh/id_hallpass
```

---

### ❌ Admin SSH key is `id_hallpass`, not `id_ed25519`

This system's admin SSH key is `~/.ssh/id_hallpass`. The conventional
`~/.ssh/id_ed25519` **does not exist** here. Always pass the `-i` flag
explicitly:

```bash
agenix -e <file> -i ~/.ssh/id_hallpass   # ✓ correct
agenix -e <file>                         # ✗ may fail or use wrong key
```

The age recipient for `bittermang` in `secrets.nix` was derived from
`id_hallpass.pub` via `cat ~/.ssh/id_hallpass.pub | ssh-to-age`.

---

### ❌ `RULES` env var not set outside the dev shell

agenix needs `RULES` to point to the root `secrets.nix` rules file. Inside
`nix-shell` or `nix develop` this is set automatically. Outside those
environments:

```bash
export RULES="$PWD/secrets.nix"
```

If `RULES` is unset, agenix looks for a `secrets.nix` in the current
directory. This works if you're in the repo root, but will silently fail or
use the wrong rules file otherwise.

---

### ❌ Malformed recipient: mixed case

age rejects public keys that aren't all-lowercase bech32. A placeholder like
`age1FILL_WITH_HALLPASS_HOST_SSH_TO_AGE_OUTPUT` will produce:

```text
age: error: malformed recipient "age1FILL_WITH...": mixed case
```

If a host key isn't known yet, **comment out** the variable entirely in
`secrets.nix` and remove it from the affected entries' `publicKeys` list.
Do not leave placeholder strings in recipient arrays.

---

### ❌ Root `secrets.nix` accidentally gitignored

The root `secrets.nix` (agenix CLI rules) must be committed. An early
`.gitignore` entry of `/secrets.nix` blocked it — this has been corrected to
`hosts/*/secrets.nix` (which is fine to commit too — it contains no plaintext
secrets, only file paths and ownership).

If `git status` shows `secrets.nix` as untracked or ignored:

```bash
git check-ignore -v secrets.nix   # find which rule is blocking it
git add -f secrets.nix            # force-add if needed
```

---

### ℹ️ HALLpass.space secrets are currently admin-only

The three HALLpass.space secrets are encrypted only for the `bittermang`
admin key. The VPS cannot decrypt them at boot until it has been provisioned
and rekeyed. See [Rekeying after VPS provisioning](#rekeying-after-vps-provisioning).

---

## VS Code Task

Use **Tasks: Run Task → 🔑 Secrets** (or the task shortcut) to see a live
status of every `.age` file — `✓` means real encrypted content, `✗` means
still a placeholder that will cause deployment to fail.
