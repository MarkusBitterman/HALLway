# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/secrets.nix - sops-nix secrets configuration (standalone HM)
# ╚════════════════╝
{ config, ... }:
{
  # Standalone Home Manager: use user's own SSH key as age identity.
  # There is no system host key; the user key is the age identity for decryption.
  sops.age.sshKeyPaths = [
    "<SSH_KEY_PATH>" # e.g. /home/<USERNAME>/.ssh/id_ed25519 or Termux path
  ];

  # The encrypted secrets file
  sops.defaultSopsFile = ./secrets.yaml;

  # ─────────────────────────────────────────────────────────────────────────
  # SSH Keys
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."ssh_key_github_automation" = {
    mode = "0600"; # No owner/group in standalone HM — files owned by HM user
  };
}
