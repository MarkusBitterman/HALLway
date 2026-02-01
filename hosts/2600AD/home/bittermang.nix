# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway v0.0.1 (2600AD)                                                  ║
# ║  home/bittermang.nix - User Environment Configuration                     ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# This file CONFIGURES programs via Home Manager (dotfiles, settings).
# Package INSTALLATION happens via roles.users.bittermang.groups in:
#   hosts/2600AD/configuration.nix
#
# Separation of concerns:
#   - roles.users.bittermang.groups → Package installation (userRoles.nix)
#   - This file (Home Manager)      → Program configuration (dotfiles)
#
# ═══════════════════════════════════════════════════════════════════════════════

{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # ═══════════════════════════════════════════════════════════════════════════
  # DESKTOP ENVIRONMENT CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════

  # Hyprland compositor
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Custom monitor resolution for older non-SmartTV (1368x768@59.85Hz)
      monitor=HDMI-A-1,1368x768@59.85,0x0,1

      # Startup applications (packages installed via roles.users in configuration.nix)
      exec-once = dunst &
      exec-once = /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 &
      exec-once = blueman-applet &
      exec-once = waybar &
      exec-once = hyprpaper &

      # Keybindings
      bind = SUPER, Return, exec, kitty
      bind = SUPER, D, exec, rofi -show drun
      bind = SUPER, Q, killactive,
      bind = SUPER SHIFT, E, exit,

      # Volume controls (PipeWire)
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    '';
  };

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # PROGRAM CONFIGURATION (not installation - that's roles.users)
  # ═══════════════════════════════════════════════════════════════════════════

  # VS Code extensions and settings
  # NOTE: VSCode binary installed via roles.users.bittermang.groups in configuration.nix
  # Home Manager extension management disabled to avoid conflicts
  # Install extensions manually via `code --install-extension` or VS Code UI

  # For now, we comment out vscode config to avoid the buildEnv conflict
  # programs.vscode = {
  #   enable = true;
  #   extensions = with pkgs.vscode-extensions; [
  #     jnoortheen.nix-ide
  #     ms-dotnettools.csharp
  #     ms-python.python
  #     ms-python.vscode-pylance
  #     rust-lang.rust-analyzer
  #   ];
  #   userSettings = {
  #     "nix.enableLanguageServer" = true;
  #     "nix.serverPath" = "nil";
  #     "editor.formatOnSave" = true;
  #     "editor.minimap.enabled" = false;
  #     "terminal.integrated.defaultProfile.linux" = "zsh";
  #   };
  # };  # SSH configuration
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Silence deprecation warning
    matchBlocks = {
      # Explicit defaults (previously implicit)
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
        };
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_github";
        identitiesOnly = true;
      };
      "hobbs" = {
        hostname = "144.202.50.58";
        user = "matt";
        identityFile = "~/.ssh/id_hobbs";
        identitiesOnly = true;
      };
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Matthew Hall";
        email = "bittermang@duck.com";
      };
      commit.gpgSign = false; # Enable after GPG setup
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    # Add zsh customizations here
  };

  programs.starship = {
    enable = true;
    # Add starship customizations here
  };
}
