# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway v0.0.1 (2600AD)                                                  ║
# ║  home/guest.nix - Guest User Environment Configuration                    ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Guest user with ephemeral home directory (tmpfs, wiped on reboot).
# "Clean room" on login, "garbage collection" on logout.
#
# Packages come from roles.users.guest.groups in configuration.nix.
# This file only configures the desktop environment.
#
# ═══════════════════════════════════════════════════════════════════════════════

{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # ═══════════════════════════════════════════════════════════════════════════
  # HYPRLAND - Minimal guest desktop
  # ═══════════════════════════════════════════════════════════════════════════

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Match bittermang's display config
      monitor=HDMI-A-1,1368x768@59.85,0x0,1

      # Startup
      exec-once = dunst &
      exec-once = waybar &
      exec-once = hyprpaper &

      # Basic keybindings
      bind = SUPER, Return, exec, kitty
      bind = SUPER, D, exec, rofi -show drun
      bind = SUPER, Q, killactive,

      # Volume controls
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
  # SHELL - Basic bash (no zsh customization for guests)
  # ═══════════════════════════════════════════════════════════════════════════

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
    };
  };
}
