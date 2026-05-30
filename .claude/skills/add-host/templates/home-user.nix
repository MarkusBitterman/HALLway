# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/home/<USERNAME>.nix - User Environment Configuration   ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝
#
# This file manages BOTH package installation AND configuration via Home Manager.
# Access control is enforced via host security policy in configuration.nix

{
  osConfig,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.doorwayde.homeManagerModules.default ];

  # ════════════════
  # DOORwayDE DESKTOP ENVIRONMENT
  # ════════════════
  doorwayde = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@60,0x0,1"; # TODO: adjust for actual display
    keyboard = "us";
  };

  wayland.windowManager.hyprland.configType = "lua";

  home.stateVersion = "25.11";

  home.sessionVariables = {
    GITHUB_TOKEN_FILE = osConfig.sops.secrets."github_token".path;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  # ════════════════
  # PACKAGE INSTALLATION
  # ════════════════

  home.packages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # ════════════════
  # SHELL
  # ════════════════

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
