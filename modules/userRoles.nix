# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/userRoles.nix - Role-Based User Management Module                ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# A NixOS module for SYSTEM-LEVEL package assignment.
#
# Philosophy (Updated):
#   - System packages (roles.users) → Essentials + Steam (library requirements)
#   - Home Manager → Everything else (dotfiles, DE apps, user programs)
#
# Why Steam is system-level:
#   Steam requires FHS environment + 32-bit libraries that are better managed
#   at the system level. Most other apps belong in Home Manager for per-user
#   dotfile control.
#
# Usage:
#   roles.users.bittermang = {
#     description = "Matthew Hall";
#     uid = 1000;
#     groups = [ "system-core" "gaming-system" ];  # System essentials only
#     extraGroups = [ "wheel" "audio" "video" ];
#   };
#
#   Then in home/bittermang.nix (Home Manager):
#     home.packages = with pkgs; [ firefox vscode obs-studio ... ];
#
# ═══════════════════════════════════════════════════════════════════════════════

{ config, pkgs, lib, ... }:

let
  cfg = config.roles;

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM-LEVEL PACKAGE GROUPS (Essentials + Steam)
  # ═══════════════════════════════════════════════════════════════════════════

  defaultPackageGroups = {

    # ─────────────────────────────────────────────────────────────────────────
    # SYSTEM CORE (CLI tools, system services)
    # ─────────────────────────────────────────────────────────────────────────

    system-core = with pkgs; [
      # Essential CLI tools
      git
      curl
      wget
      rsync
      tree
      htop
      tmux

      # Encryption/security
      age
      gnupg

      # Compression
      gzip
      bzip2
      xz
      unzip
      zip
    ];

    system-dev = with pkgs; [
      # Development essentials (compilers, build tools)
      gnumake
      gcc
      pkg-config

      # Language runtimes (system-wide for build deps)
      python3
      nodejs
    ];

    system-admin = with pkgs; [
      # System monitoring
      iotop
      lsof
      strace

      # Networking
      tcpdump
      nmap

      # Disk utils
      ncdu
      duf

      # Android
      android-tools
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # GAMING (Steam + dependencies - MUST be system-level)
    # ─────────────────────────────────────────────────────────────────────────

    gaming-system = with pkgs; [
      steam                 # FHS env + 32-bit libs
      gamemode              # System service
      mangohud              # Library injection
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
