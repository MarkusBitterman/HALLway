# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/secrets.nix - sops-nix secrets configuration           ║
# ╚════════════════╝
{ config, ... }:
{
  # Use the SSH host key to decrypt secrets at activation time
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # The encrypted secrets file (YAML with encrypted values)
  sops.defaultSopsFile = ./secrets.yaml;

  # ─────────────────────────────────────────────────────────────────────────
  # SSH Keys
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."ssh_key_github_automation" = {
    owner = "<USERNAME>";
    group = "users";
    mode = "0600";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # WireGuard
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."wg_privatekey" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
