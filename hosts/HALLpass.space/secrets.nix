{ ... }:
{
  # SSH host private keys used by agenix to decrypt secrets at activation time.
  # The ed25519 key is preferred; rsa is kept as fallback.
  # These are the same keys openssh generates on first boot and that ACME uses.
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];

  # SSH key for administrative git operations
  age.secrets."ssh_key_github" = {
    file = ./secrets/ssh_key_github.age;
    owner = "matt";
    group = "users";
    mode = "0600";
  };

  # WireGuard server private key
  age.secrets."wg-hallpass-privatekey" = {
    file = ./secrets/wg-hallpass-privatekey.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Syncthing GUI password (plaintext; Syncthing hashes internally)
  age.secrets."syncthing-gui-pass" = {
    file = ./secrets/syncthing-gui-pass.age;
    owner = "syncthing";
    group = "syncthing";
    mode = "0400";
  };

  # Vultr API key for lego DNS-01 ACME challenge (wildcard cert)
  # File content: VULTR_API_KEY=<your-vultr-api-key>
  # Key needs DNS write permission in Vultr control panel.
  age.secrets."acme-vultr-api-key" = {
    file = ./secrets/acme-vultr-api-key.age;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
}
