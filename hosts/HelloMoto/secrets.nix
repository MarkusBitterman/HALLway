# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/HelloMoto/secrets.nix - sops-nix secrets configuration (phone)    ║
# ╚════════════════╝
{ config, ... }:
{
  # Phone SSH key used as the age identity for decryption.
  # There is no system host key on Android; the user's own key is the identity.
  sops.age.sshKeyPaths = [
    "/data/data/com.termux/files/home/.ssh/id_ed25519"
  ];

  # The encrypted secrets file
  sops.defaultSopsFile = ./secrets.yaml;

  # SSH key for GitHub operations on the phone
  sops.secrets."ssh_key_github" = {
    mode = "0600";
  };
}
