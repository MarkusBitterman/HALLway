# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/2600AD/secrets.nix - sops-nix secrets configuration                ║
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
  sops.secrets."ssh_key_github" = {
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  sops.secrets."ssh_key_hobbs" = {
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  sops.secrets."ssh_key_hallpass" = {
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # Tokens & Credentials
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."github_token" = {
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  sops.secrets."gpg_key" = {
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  sops.secrets."syncthing_gui_pass" = {
    owner = "bittermang";
    group = "users";
    mode = "0400";
  };

  # Vultr API key (for DNS management, future automation)
  sops.secrets."vultr_api_key" = {
    owner = "bittermang";
    group = "users";
    mode = "0400";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # WireGuard
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."wg_privatekey" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."wg_psk" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # WiFi (iwd format)
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."wifi_home" = {
    path = "/var/lib/iwd/Minus World.psk";
    owner = "root";
    group = "root";
    mode = "0600";
  };
}
