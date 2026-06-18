# ╔════════════════╗
# ║  HALLway v0.0.1 (2600AD)                                                  ║
# ║  home/guest.nix - Guest User Environment Configuration                    ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝
#
# Guest user with ephemeral home directory (tmpfs, wiped on reboot).
# "Clean room" on login, "garbage collection" on logout.
#
# Packages come from host-level `users.users.guest.packages` in configuration.nix.
# This file configures the guest desktop environment via DOORway.
#
# ════════════════════

{ inputs, pkgs, ... }:

{
  home.stateVersion = "25.11";

  imports = [ inputs.doorway.homeManagerModules.default ];

  doorway = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@59.85,0x0,1";
    keyboard = "us";
    # Packages (kitty, rofi, waybar, etc.) are provided at the system level
    # via users.users.guest.packages in configuration.nix — skip HM duplication.
    installPackages = false;
  };

  # ════════════════
  # SHELL - Basic bash (no zsh customization for guests)
  # ════════════════

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
    };
  };
}
