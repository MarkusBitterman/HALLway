# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/userRoles.nix - Role-Based User Management Module                ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# A NixOS module for role-based package assignment.
#
# Philosophy:
#   Users are defined by what they DO (roles), not just what they can ACCESS.
#   Packages are installed via roles.users.<name>.groups.
#   Home Manager configures those programs (dotfiles, settings), NOT installation.
#
# Usage:
#   roles.users.bittermang = {
#     description = "Matthew Hall";
#     uid = 1000;
#     groups = [ "developers" "desktop" "viewers" "communication" ];
#     extraGroups = [ "wheel" "audio" "video" ];
#   };
#
# Available groups:
#   core          - CLI essentials (git, curl, htop, etc.)
#   developers    - Programming tools (vscode, neovim, rustup, etc.)
#   desktop       - Hyprland/Wayland (kitty, rofi, waybar, etc.)
#   gaming        - Steam + gaming tools
#   viewers       - Media viewers (mpv, vlc, spotify, loupe)
#   editors       - Image editors (gimp, inkscape, krita)
#   producers     - A/V production (obs, kdenlive, ffmpeg) ⚠️ HEAVY
#   gamedev       - Game development (unity, blender)
#   communication - Web, chat, office (firefox, discord, obsidian)
#   sysadmin      - System admin tools (iotop, nmap, tcpdump)
#
# ═══════════════════════════════════════════════════════════════════════════════

{ config, pkgs, lib, ... }:

let
  cfg = config.roles;

  # ═══════════════════════════════════════════════════════════════════════════
  # PACKAGE GROUPS - What users DO determines what they GET
  # ═══════════════════════════════════════════════════════════════════════════

  defaultPackageGroups = {

    # ─────────────────────────────────────────────────────────────────────────
    # CORE - Everyone gets these
    # ─────────────────────────────────────────────────────────────────────────

    core = with pkgs; [
      git curl wget rsync tree htop tmux
      age gnupg                           # Encryption
      gzip bzip2 xz unzip zip             # Compression
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # DEVELOPERS - Programming and dev tools
    # ─────────────────────────────────────────────────────────────────────────

    developers = with pkgs; [
      # Editors
      neovim
      vscode

      # CLI dev tools
      gh                                  # GitHub CLI
      jq
      ripgrep
      fd
      btop

      # Build essentials
      gnumake gcc pkg-config
      python3 nodejs

      # Rust
      rustup
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # DESKTOP - Wayland/Hyprland environment
    # ─────────────────────────────────────────────────────────────────────────

    desktop = with pkgs; [
      # Terminal & launcher
      kitty
      rofi

      # File manager
      pcmanfm

      # Status bar & notifications
      waybar
      dunst

      # Wallpaper
      hyprpaper

      # Audio control
      pavucontrol
      playerctl

      # Authentication
      polkit_gnome

      # Portal
      xdg-desktop-portal-hyprland
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # GAMING - Steam + tools
    # ─────────────────────────────────────────────────────────────────────────

    gaming = with pkgs; [
      steam                               # FHS env + 32-bit libs
      steamcmd
      steam-tui
      gamemode
      mangohud
      winetricks
      protontricks

      # Other stores
      minigalaxy                          # GOG
      itch
      heroic                              # Epic/GOG/Amazon
      retroarch
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # VIEWERS - Media consumption (lightweight)
    # ─────────────────────────────────────────────────────────────────────────

    viewers = with pkgs; [
      # Image viewers
      loupe gthumb
      imagemagick                         # CLI image tools

      # Video players
      mpv vlc celluloid

      # Music players
      spotify
      rhythmbox
      playerctl

      # Documents
      zathura                             # PDF viewer
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # EDITORS - Image/document editing (medium weight)
    # ─────────────────────────────────────────────────────────────────────────

    editors = with pkgs; [
      gimp inkscape krita darktable

      # Music tagging
      picard easytag soundconverter
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # PRODUCERS - Video/audio production (HEAVY - ffmpeg, kdenlive, etc.)
    # ─────────────────────────────────────────────────────────────────────────

    producers = with pkgs; [
      # Video production (these pull ffmpeg)
      obs-studio
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-pipewire-audio-capture
      kdePackages.kdenlive
      shotcut
      handbrake
      ffmpeg

      # Music production
      ardour lmms
      surge-XT vital calf lsp-plugins
      qsynth carla
      easyeffects helvum qpwgraph
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # GAMEDEV - Game development tools
    # ─────────────────────────────────────────────────────────────────────────

    gamedev = with pkgs; [
      unityhub
      blender
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # COMMUNICATION - Web, chat, office
    # ─────────────────────────────────────────────────────────────────────────

    communication = with pkgs; [
      firefox
      chromium
      discord
      element-desktop
      signal-desktop

      # Office
      onlyoffice-desktopeditors
      obsidian
      zathura
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # SYSADMIN - System administration tools
    # ─────────────────────────────────────────────────────────────────────────

    sysadmin = with pkgs; [
      iotop lsof strace
      tcpdump nmap
      ncdu duf
      android-tools
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # HELPER FUNCTIONS
  # ═══════════════════════════════════════════════════════════════════════════

  # Resolve packages for a list of group names
  packagesForGroups = groups:
    lib.unique (lib.flatten (map (g: cfg.packageGroups.${g} or []) groups));

  # User submodule type definition
  userSubmodule = lib.types.submodule ({ name, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable this user.";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "User's display name/description.";
      };

      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "User's UID. If null, NixOS assigns one automatically.";
      };

      shell = lib.mkOption {
        type = lib.types.package;
        default = pkgs.zsh;
        description = "User's login shell.";
      };

      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of package groups to assign to this user.
          Available groups: ${lib.concatStringsSep ", " (lib.attrNames defaultPackageGroups)}
        '';
        example = [ "developers" "gaming" "desktop" ];
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional Unix groups (wheel, audio, video, etc.)";
        example = [ "wheel" "audio" "video" ];
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional packages specific to this user.";
        example = lib.literalExpression "[ pkgs.blender pkgs.unityhub ]";
      };

      isGuest = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether this is a guest user with ephemeral home directory.
          Guest users get a tmpfs home that is wiped on each reboot.
        '';
      };

      guestTmpfsSize = lib.mkOption {
        type = lib.types.str;
        default = "2G";
        description = "Size of tmpfs for guest home directory.";
      };
    };
  });

in
{
  # ═══════════════════════════════════════════════════════════════════════════
  # MODULE OPTIONS
  # ═══════════════════════════════════════════════════════════════════════════

  options.roles = {

    packageGroups = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.package);
      default = defaultPackageGroups;
      description = ''
        Package groups that can be assigned to users.
        Keys are group names, values are lists of packages.
      '';
      example = lib.literalExpression ''
        {
          my-custom-group = with pkgs; [ foo bar baz ];
        }
      '';
    };

    users = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = {};
      description = ''
        User definitions with role-based package assignment.
        Each user can be assigned to package groups and will receive
        all packages from those groups.
      '';
      example = lib.literalExpression ''
        {
          alice = {
            description = "Alice";
            uid = 1000;
            groups = [ "developers" "desktop" ];
            extraGroups = [ "wheel" ];
          };
          bob = {
            description = "Bob";
            groups = [ "gaming" "desktop" ];
            isGuest = true;
          };
        }
      '';
    };

    # Convenience functions exposed to other modules
    lib = lib.mkOption {
      type = lib.types.attrs;
      default = {
        inherit packagesForGroups;
        availableGroups = lib.attrNames cfg.packageGroups;
      };
      readOnly = true;
      description = "Helper functions for use in other modules.";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # MODULE IMPLEMENTATION
  # ═══════════════════════════════════════════════════════════════════════════

  config = lib.mkIf (cfg.users != {}) {

    # ─────────────────────────────────────────────────────────────────────────
    # USER ACCOUNTS
    # ─────────────────────────────────────────────────────────────────────────

    users.users = lib.mapAttrs (name: userCfg: {
      isNormalUser = true;
      description = userCfg.description;
      shell = userCfg.shell;
      extraGroups = userCfg.extraGroups;
      packages = (packagesForGroups userCfg.groups) ++ userCfg.extraPackages;
    } // (lib.optionalAttrs (userCfg.uid != null) {
      uid = userCfg.uid;
    })) (lib.filterAttrs (n: u: u.enable) cfg.users);

    # ─────────────────────────────────────────────────────────────────────────
    # SYSTEM GROUPS
    # ─────────────────────────────────────────────────────────────────────────

    # Create gamemode group if any user has gaming
    users.groups.gamemode = lib.mkIf (lib.any
      (u: lib.elem "gaming" u.groups)
      (lib.attrValues cfg.users)
    ) {};

    # ─────────────────────────────────────────────────────────────────────────
    # GUEST USER TMPFS
    # ─────────────────────────────────────────────────────────────────────────

    fileSystems = lib.mkMerge (lib.mapAttrsToList (name: userCfg:
      lib.optionalAttrs userCfg.isGuest {
        "/home/${name}" = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [
            "size=${userCfg.guestTmpfsSize}"
            "mode=0700"
            "uid=${toString (userCfg.uid or 1001)}"
            "gid=100"  # users group
          ];
        };
      }
    ) cfg.users);

    # ─────────────────────────────────────────────────────────────────────────
    # GUEST SKELETON SETUP
    # ─────────────────────────────────────────────────────────────────────────

    system.activationScripts = lib.mkMerge (lib.mapAttrsToList (name: userCfg:
      lib.optionalAttrs userCfg.isGuest {
        "guestSkeleton-${name}" = lib.stringAfter [ "users" ] ''
          # Set up guest home directory structure
          mkdir -p /home/${name}/.config
          mkdir -p /home/${name}/Downloads
          mkdir -p /home/${name}/Pictures
          mkdir -p /home/${name}/Videos
          mkdir -p /home/${name}/Music

          # Copy skeleton files if available
          if [ -d /etc/skel ]; then
            cp -rn /etc/skel/. /home/${name}/ 2>/dev/null || true
          fi

          # Fix ownership
          chown -R ${name}:users /home/${name}
        '';
      }
    ) cfg.users);
  };
}
