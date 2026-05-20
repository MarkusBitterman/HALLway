# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/userRoles.nix - AppArmor-Enforced Role-Based Access Control      ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝
#
# Group-based application access control with AppArmor enforcement.
# Packages installed via Home Manager, access controlled via Unix groups.
#
# Philosophy:
#   Users are defined by what they DO (roles), not just what they can ACCESS.
#   - Packages installed via Home Manager (home.packages)
#   - Access enforced via AppArmor profiles (deny by default)
#   - Unix groups determine which applications users can execute
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
#   core          - System utilities (no AppArmor enforcement, universally accessible)
#   developers    - Programming tools (vscode, neovim, rustup, etc.)
#   desktop       - Hyprland/Wayland (kitty, rofi, waybar, etc.)
#   gaming        - Gaming tools (controllers, emulators, overlays - Steam is system-level)
#   viewers       - Media viewers (mpv, vlc, spotify, loupe)
#   editors       - Image editors (gimp, inkscape, krita)
#   producers     - A/V production (obs, kdenlive, ardour)
#   gamedev       - Game development (unity, blender)
#   communication - Web, chat, office (firefox, discord, obsidian)
#   sysadmin      - System admin tools (iotop, nmap, tcpdump)
#
# ════════════════════

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.roles;

  # ════════════════
  # APPLICATION GROUPS - Binary paths for AppArmor enforcement
  # ════════════════

  # Core utilities - no AppArmor enforcement (universally accessible)
  # These are system essentials that all users need

  defaultApplicationGroups = {

    # ─────────────────────────────────────────────────────────────────────────
    # DEVELOPERS - Programming and dev tools
    # ─────────────────────────────────────────────────────────────────────────

    developers = {
      binaries = [
        "code"
        "code-insiders" # VS Code
        "nvim"
        "vim" # Editors
        "gh" # GitHub CLI
        "rustc"
        "cargo"
        "rustup" # Rust
        "python"
        "python3"
        "uv" # Python
        "node"
        "npm"
        "npx" # Node.js
        "java"
        "javac" # Java
        "make"
        "gcc"
        "g++" # Build tools
        "nixd"
        "nil" # Nix LSP
      ];
      description = "Programming and development tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # DESKTOP - Hyprland/Wayland environment
    # ─────────────────────────────────────────────────────────────────────────

    desktop = {
      binaries = [
        "kitty" # Terminal
        "rofi"
        "rofi-theme-selector" # Launcher
        "waybar" # Status bar
        "dunst"
        "dunstctl" # Notifications
        "hyprpaper" # Wallpaper
        "pcmanfm" # File manager
        "pavucontrol" # Audio control
        "playerctl" # Media control
      ];
      description = "Hyprland desktop environment components";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # GAMING - Gaming tools (Steam installed system-wide separately)
    # ─────────────────────────────────────────────────────────────────────────

    gaming = {
      binaries = [
        "steam"
        "steam-runtime"
        "steamcmd" # Steam (system-level)
        "gamemode"
        "gamemoded"
        "gamemoderun" # Performance
        "mangohud" # Overlay
        "protontricks" # Proton tools
        "minigalaxy" # GOG
        "heroic" # Epic/GOG/Amazon
        "itch" # Itch.io
        "cemu" # Wii U emulator
        "dosbox" # DOS
        "limo" # Alternative launcher
        "wine"
        "wine64"
        "wineserver" # Wine
        "winetricks" # Wine configuration
      ];
      description = "Gaming applications and tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # VIEWERS - Media consumption
    # ─────────────────────────────────────────────────────────────────────────

    viewers = {
      binaries = [
        "loupe"
        "gthumb" # Image viewers
        "convert"
        "identify"
        "mogrify" # ImageMagick
        "mpv" # Video player
        "vlc" # Video player
        "celluloid" # Video player (MPV frontend)
        "spotify" # Music streaming
        "rhythmbox"
        "rhythmbox-client" # Music player
        "zathura" # PDF viewer
      ];
      description = "Media viewing applications";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # EDITORS - Image/document editing
    # ─────────────────────────────────────────────────────────────────────────

    editors = {
      binaries = [
        "gimp"
        "gimp-2.10" # Image editor
        "inkscape" # Vector graphics
        "krita" # Digital painting
        "darktable" # Photo workflow
        "picard" # Music tagging
        "easytag" # Audio tagging
        "soundconverter" # Audio conversion
      ];
      description = "Image and document editing tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # PRODUCERS - Video/audio production
    # ─────────────────────────────────────────────────────────────────────────

    producers = {
      binaries = [
        "obs"
        "obs-studio" # Video recording
        "kdenlive" # Video editing
        "handbrake"
        "ghb" # Video transcoding
        "ffmpeg"
        "ffprobe"
        "ffplay" # Media processing
        "ardour"
        "ardour8" # DAW
        "lmms" # Music production
        "surge-xt" # Synthesizer
        "vital" # Synthesizer
        "qsynth" # FluidSynth GUI
        "carla"
        "carla-control" # Plugin host
        "easyeffects" # Audio effects
        # "helvum" removed (unmaintained) - use qpwgraph
        "qpwgraph" # PipeWire patchbay
      ];
      description = "Audio and video production tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # GAMEDEV - Game development
    # ─────────────────────────────────────────────────────────────────────────

    gamedev = {
      binaries = [
        "unityhub"
        "unity-editor" # Unity
        "blender" # 3D modeling
        "pince" # Memory editor
        "scanmem"
        "gameconqueror" # Memory scanning
      ];
      description = "Game development tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # COMMUNICATION - Web, chat, office
    # ─────────────────────────────────────────────────────────────────────────

    communication = {
      binaries = [
        "firefox"
        "firefox-esr" # Browser
        "chromium"
        "chrome" # Browser
        "discord"
        "Discord" # Chat
        "element-desktop" # Matrix client
        "signal-desktop" # Secure messaging
        "thunderbird" # Email
        "geary" # Email
        "onlyoffice-desktopeditors" # Office suite
        "libreoffice"
        "soffice"
        "lowriter"
        "localc"
        "loimpress" # LibreOffice
        "obsidian" # Notes
      ];
      description = "Communication and productivity tools";
    };

    # ─────────────────────────────────────────────────────────────────────────
    # SYSADMIN - System administration
    # ─────────────────────────────────────────────────────────────────────────

    sysadmin = {
      binaries = [
        "iotop" # I/O monitoring
        "lsof" # Open files
        "strace" # System call tracing
        "tcpdump" # Network capture
        "nmap" # Network scanner
        "ncdu" # Disk usage
        "duf" # Disk usage (modern)
        "adb"
        "fastboot" # Android tools
        "gparted" # Partition editor
        "stress-ng" # Stress testing
      ];
      description = "System administration tools";
    };
  };

  # ════════════════
  # HELPER FUNCTIONS
  # ════════════════

  # ════════════════
  # HELPER FUNCTIONS
  # ════════════════

  # Get all binaries for a list of group names
  binariesForGroups =
    groups: lib.unique (lib.flatten (map (g: cfg.applicationGroups.${g}.binaries or [ ]) groups));

  # User submodule type definition
  userSubmodule = lib.types.submodule (
    { name, ... }:
    {
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
          default = [ ];
          description = ''
            List of application groups for access control.
            Users can only execute applications from groups they belong to (AppArmor enforced).
            Available groups: ${lib.concatStringsSep ", " (lib.attrNames defaultApplicationGroups)}

            Note: 'core' utilities are universally accessible (no AppArmor enforcement).
          '';
          example = [
            "developers"
            "gaming"
            "desktop"
          ];
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional Unix groups (wheel, audio, video, etc.)";
          example = [
            "wheel"
            "audio"
            "video"
          ];
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            Additional packages for guest users (system-level only).
            Regular users should use Home Manager's home.packages instead.
            This option is primarily for guest users with ephemeral tmpfs homes.
          '';
          example = lib.literalExpression "[ pkgs.firefox pkgs.vlc ]";
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
    }
  );

in
{
  # ════════════════
  # MODULE OPTIONS
  # ════════════════

  options.roles = {

    applicationGroups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            binaries = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of binary names that require this group for execution.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Human-readable description of this application group.";
            };
            customProfile = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Custom AppArmor profile override for this group's applications.";
            };
          };
        }
      );
      default = defaultApplicationGroups;
      description = ''
        Application groups defining which binaries require which group membership.
        Keys are group names (matching Unix groups), values define binaries and AppArmor profiles.
      '';
      example = lib.literalExpression ''
        {
          my-custom-group = {
            binaries = [ "myapp" "myapp-cli" ];
            description = "My custom application group";
          };
        }
      '';
    };

    users = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = { };
      description = ''
        User definitions with role-based access control.
        Each user is assigned to application groups, determining which apps they can execute.

        Regular users: Packages installed via Home Manager (home.packages)
        Guest users: Packages installed system-level (ephemeral tmpfs homes)
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
            extraPackages = with pkgs; [ firefox vlc ];
          };
        }
      '';
    };

    # Convenience functions exposed to other modules
    lib = lib.mkOption {
      type = lib.types.attrs;
      default = {
        inherit binariesForGroups;
        availableGroups = lib.attrNames cfg.applicationGroups;
      };
      readOnly = true;
      description = "Helper functions for use in other modules.";
    };
  };

  # ════════════════
  # MODULE IMPLEMENTATION
  # ════════════════

  config = lib.mkIf (cfg.users != { }) {

    # ─────────────────────────────────────────────────────────────────────────
    # USER ACCOUNTS
    # ─────────────────────────────────────────────────────────────────────────

    users.users = lib.mapAttrs (
      name: userCfg:
      {
        isNormalUser = true;
        description = userCfg.description;
        shell = userCfg.shell;
        extraGroups = userCfg.extraGroups ++ userCfg.groups; # Add role groups to Unix groups

        # Only install packages for guest users (ephemeral tmpfs)
        # Regular users get packages via Home Manager
        packages = lib.optionals userCfg.isGuest userCfg.extraPackages;
      }
      // (lib.optionalAttrs (userCfg.uid != null) {
        uid = userCfg.uid;
      })
    ) (lib.filterAttrs (n: u: u.enable) cfg.users);

    # ─────────────────────────────────────────────────────────────────────────
    # UNIX GROUPS (for AppArmor enforcement)
    # ─────────────────────────────────────────────────────────────────────────

    users.groups = lib.listToAttrs (
      # Create Unix group for each application group
      lib.mapAttrsToList (groupName: groupCfg: lib.nameValuePair groupName { }) cfg.applicationGroups
    );

    # ─────────────────────────────────────────────────────────────────────────
    # APPARMOR ENFORCEMENT
    # ─────────────────────────────────────────────────────────────────────────

    security.apparmor = {
      enable = true;
      packages = [ pkgs.apparmor-profiles ];
    };

    # Enable AppArmor kernel LSM (via security.lsm, not kernel params)
    boot.kernelParams = [ "apparmor=1" ];

    # ─────────────────────────────────────────────────────────────────────────
    # GUEST USER TMPFS
    # ─────────────────────────────────────────────────────────────────────────

    fileSystems = lib.mkMerge (
      lib.mapAttrsToList (
        name: userCfg:
        lib.optionalAttrs userCfg.isGuest {
          "/home/${name}" = {
            device = "tmpfs";
            fsType = "tmpfs";
            options = [
              "size=${userCfg.guestTmpfsSize}"
              "mode=0700"
              "uid=${toString (userCfg.uid or 1001)}"
              "gid=100" # users group
            ];
          };
        }
      ) cfg.users
    );

    # ─────────────────────────────────────────────────────────────────────────
    # GUEST SKELETON SETUP
    # ─────────────────────────────────────────────────────────────────────────

    system.activationScripts = lib.mkMerge (
      lib.mapAttrsToList (
        name: userCfg:
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
      ) cfg.users
    );
  };
}
