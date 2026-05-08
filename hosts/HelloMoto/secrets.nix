{ ... }:
{
  # Phone SSH key used as the age identity for decryption.
  # There is no system host key on Android; the user's own key is the identity.
  age.identityPaths = [
    "/data/data/com.termux/files/home/.ssh/id_ed25519"
  ];

  # SSH key for GitHub operations on the phone
  age.secrets."ssh_key_github" = {
    file = ./secrets/ssh_key_github.age;
    mode = "0600";
  };
}
