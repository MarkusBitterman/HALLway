{ config, ... }: {
  # SSH key for GitHub
  age.secrets."ssh_key_github" = {
    file = ./secrets/ssh_key_github.age;
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  # SSH key for hobbs server
  age.secrets."ssh_key_hobbs" = {
    file = ./secrets/ssh_key_hobbs.age;
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  # GitHub personal access token
  age.secrets."github_token" = {
    file = ./secrets/github_token.age;
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };

  # GPG private key for commit signing
  age.secrets."gpg_key" = {
    file = ./secrets/gpg_key.age;
    owner = "bittermang";
    group = "users";
    mode = "0600";
  };
}
