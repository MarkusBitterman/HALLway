# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/home/<USERNAME>.nix - <DESCRIPTION>                    ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{ config, pkgs, ... }:

{
  imports = [ ../secrets.nix ];

  home.username = "<USERNAME>";
  home.homeDirectory = "<HOME_DIRECTORY>"; # e.g. /home/<USERNAME> or /data/data/com.termux/files/home

  home.stateVersion = "25.11";

  # ════════════════════════════════════════════════════════════════════════
  # PACKAGES
  # ════════════════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    git
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

  programs.git = {
    enable = true;
    settings.user = {
      name = "Matthew Hall";
      email = "bittermang@duck.com";
    };
  };
}
