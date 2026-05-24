# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/HALLpass.space/secrets.nix - sops-nix secrets configuration        ║
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
    owner = "matt";
    group = "users";
    mode = "0600";
  };

  sops.secrets."ssh_key_hobbs" = {
    owner = "matt";
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

  sops.secrets."wg_desktop_psk" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # Services
  # ─────────────────────────────────────────────────────────────────────────
  sops.secrets."syncthing_gui_pass" = {
    owner = "syncthing";
    group = "syncthing";
    mode = "0400";
  };

  # Vultr API key for lego DNS-01 ACME challenge (wildcard cert)
  sops.secrets."acme_vultr_api_key" = {
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
}
