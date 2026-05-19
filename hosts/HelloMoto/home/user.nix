# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/HelloMoto/home/user.nix - Phone User Environment (Termux/Nix)     ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{ config, pkgs, ... }:

let
  # Replace with the output of `whoami` in Termux (e.g. "u0_a231")
  phoneUser = "PHONE_USERNAME";
  phoneHome = "/data/data/com.termux/files/home";
in
{
  imports = [ ../secrets.nix ];

  home.username = phoneUser;
  home.homeDirectory = phoneHome;
  home.stateVersion = "26.05";

  # ════════════════════════════════════════════════════════════════════════
  # PACKAGES
  # ════════════════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # Core tooling
    git
    mercurial
    jq

    # Secrets tooling
    age
    ssh-to-age
  ];

  # ════════════════════════════════════════════════════════════════════════
  # SHELL
  # ════════════════════════════════════════════════════════════════════════

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # ════════════════════════════════════════════════════════════════════════
  # SSH
  # ════════════════════════════════════════════════════════════════════════

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identityFile = config.sops.secrets."ssh_key_github".path;
        identitiesOnly = true;
        user = "git";
      };
      "hallpass" = {
        hostname = "hallpass.space";
        user = "matt";
        identityFile = "${phoneHome}/.ssh/id_ed25519";
      };
      "2600ad" = {
        hostname = "DESKTOP_IP_OR_HOSTNAME";
        user = "bittermang";
        identityFile = "${phoneHome}/.ssh/id_ed25519";
      };
    };
  };
}
