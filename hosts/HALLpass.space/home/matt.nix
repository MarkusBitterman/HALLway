# ╔════════════════╗
# ║  HALLway v0.0.1 (HALLpass.space)                                          ║
# ║  home/matt.nix - Minimal VPS User Environment                              ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝
#
# This file manages BOTH package installation AND configuration via Home Manager.
# Access control is enforced via host security policy in configuration.nix
#
# Package installation:
#   - home.packages → All user applications (organized by category)
#
# Separation of concerns:
#   - This file (Home Manager) → Package installation + configuration
#   - host configuration        → security/access policy (AppArmor)
#
# ════════════════════

{ osConfig, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # Minimal operator toolset for a 25GB VPS.
  home.packages = with pkgs; [

    # Core administration
    git
    curl
    wget
    tmux
    # jq in configuration.nix systemPackages

    # Security tools (age, ssh-to-age) in configuration.nix systemPackages
    # gnupg removed: pulls X11 deps via pinentry. If needed headless:
    # (gnupg.override { guiSupport = false; })

    # Diagnostics (keep sparse)
    htop
    ncdu
    lsof
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = osConfig.sops.secrets."ssh_key_github_automation".path;
        IdentitiesOnly = "yes";
      };
      "hobbs" = {
        HostName = "hobbsfamilycleaning.us";
        User = "matt";
        IdentityFile = "~/.ssh/id_hobbs";
        IdentitiesOnly = "yes";
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

  # Direnv - automatic Nix environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
