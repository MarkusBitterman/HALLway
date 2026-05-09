# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  secrets.nix - agenix encryption rules                                    ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝
#
# PURPOSE: This is the agenix CLI rules file (NOT the NixOS module config).
# It tells `agenix -e <file>` which age public keys can decrypt each secret.
#
# Per-host NixOS module declarations are in hosts/<hostname>/secrets.nix.
#
# SETUP: Before creating or editing secrets, fill in the three recipient keys
# below. Use `ssh-to-age` to convert SSH public keys to age format:
#
#   Admin key (bittermang, run on 2600AD):
#     cat ~/.ssh/id_hallpass.pub | ssh-to-age
#     (this system uses id_hallpass — not the default id_ed25519)
#
#   2600AD host key (run on 2600AD):
#     ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
#
#   HALLpass.space host key (run after first VPS boot):
#     ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
#
# See docs/secrets.md for the full secrets lifecycle.
# ════════════════════════════════════════════════════════════════════════════

let
  # ── Recipient: bittermang (admin, manages all secrets from 2600AD) ────────
  # derived: cat ~/.ssh/id_hallpass.pub | ssh-to-age
  bittermang = "age1s7esczqlsehs6vl7w7ye6acl8ecrj4t2r4xsxmfv9jmhv2h2dvgqx0yls9";

  # ── Recipient: 2600AD system SSH host key (decrypts at boot/switch time) ──
  # derived: ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
  host2600AD = "age1hhyeuve5crq8edq57r06g7evc7wm0jjv63jgk2eyt6mj79zwkgfquvj25s";

  # ── Recipient: HALLpass.space system SSH host key (decrypts at boot/switch)
  # Uncomment and fill in after first VPS deploy:
  #   ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
  # Then rekey: agenix -r -i ~/.ssh/id_hallpass
  # hallpass = "age1FILL_WITH_HALLPASS_HOST_SSH_TO_AGE_OUTPUT";

  # ── Recipient: HelloMoto phone SSH user key (decrypts in Termux) ──────────
  # No system host key on Android; the user's SSH key is the identity.
  # On the phone: cat ~/.ssh/id_ed25519.pub | ssh-to-age
  # Then uncomment and fill in:
  # hellomoto = "age1FILL_WITH_PHONE_SSH_TO_AGE_OUTPUT";

in
{
  # ─── 2600AD ───────────────────────────────────────────────────────────────
  # Encrypted for both admin (can edit) + host (can deploy).
  "hosts/2600AD/secrets/ssh_key_github.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/ssh_key_hobbs.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/ssh_key_hallpass.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/github_token.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/gpg_key.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/wg-2600ad-privatekey.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/wg-hallspace-psk.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/syncthing-gui-pass.age".publicKeys = [
    bittermang
    host2600AD
  ];
  "hosts/2600AD/secrets/wifi-home.age".publicKeys = [
    bittermang
    host2600AD
  ];

  # ─── HelloMoto (phone) ────────────────────────────────────────────────────
  # Currently encrypted for admin only — phone SSH key not yet known.
  # After first activation: cat ~/.ssh/id_ed25519.pub | ssh-to-age on the phone,
  # fill in `hellomoto` above, add to publicKeys, then rekey.
  "hosts/HelloMoto/secrets/ssh_key_github.age".publicKeys = [
    bittermang
  ];

  # ─── HALLpass.space ───────────────────────────────────────────────────────
  # Currently encrypted for admin only — hallpass host key not yet known.
  # After first VPS deploy: fill in `hallpass` above, then run:
  #   agenix -r -i ~/.ssh/id_hallpass
  "hosts/HALLpass.space/secrets/ssh_key_github.age".publicKeys = [
    bittermang
  ];
  "hosts/HALLpass.space/secrets/wg-hallpass-privatekey.age".publicKeys = [
    bittermang
  ];
  "hosts/HALLpass.space/secrets/wg-desktop-psk.age".publicKeys = [
    bittermang
  ];
  "hosts/HALLpass.space/secrets/syncthing-gui-pass.age".publicKeys = [
    bittermang
  ];
  "hosts/HALLpass.space/secrets/acme-vultr-api-key.age".publicKeys = [
    bittermang
  ];
}
