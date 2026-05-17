# ╔════════════════╗
# ║  HALLway v0.0.1 (2600AD)                                                  ║
# ║  home/bittermang.nix - User Environment Configuration                     ║
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
#   - host configuration        → security/access policy (AppArmor/SELinux)
#
# ════════════════════

{ osConfig, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # Runtime paths to decrypted agenix secrets (NixOS module).
  # These resolve under /run/agenix/<name> at activation time.
  home.sessionVariables = {
    GITHUB_TOKEN_FILE = osConfig.age.secrets."github_token".path;
    GPG_PRIVATE_KEY_FILE = osConfig.age.secrets."gpg_key".path;
  };

  # ════════════════
  # PACKAGE INSTALLATION
  # ════════════════

  home.packages = with pkgs; [

    # ─────────────────────────────────────────────────────────────────────────
    # CORE - System utilities (universally accessible, no AppArmor enforcement)
    # ─────────────────────────────────────────────────────────────────────────

    git
    curl
    wget
    rsync
    tree
    btop
    tmux
    age
    gnupg # Encryption
    gzip
    bzip2
    xz
    unzip
    zip # Compression
    desktop-file-utils # Desktop integration

    # ─────────────────────────────────────────────────────────────────────────
    # DEVELOPERS - Programming and dev tools
    # ─────────────────────────────────────────────────────────────────────────

    # Editors
    neovim
    vscodium-fhs
    claude-code

    # CLI dev tools
    gh # GitHub CLI
    mercurial
    jq
    ripgrep
    fd
    btop
    pciutils # lspci, etc.
    imagemagick

    # Build essentials
    gnumake
    gcc
    pkg-config
    python3
    uv
    nodejs

    # Rust
    rustup

    # Nix development
    direnv
    nix-direnv
    nixd
    nixfmt

    # HTML/Web
    html5validator
    djlint
    sqlite

    # Java
    # jre # jdk #handled now by jetbrains, above?

    # ─────────────────────────────────────────────────────────────────────────
    # DESKTOP - Hyprland/Wayland environment
    # ─────────────────────────────────────────────────────────────────────────

    kitty # Terminal
    rofi # Launcher
    pcmanfm # File manager
    waybar # Status bar
    dunst # Notifications
    hyprpaper # Wallpaper
    pavucontrol # Audio control
    playerctl # Media control
    polkit_gnome # Authentication agent
    iwgtk # WiFi manager (iwd frontend, Wayland tray)

    # ─────────────────────────────────────────────────────────────────────────
    # GAMING - Gaming tools (Steam installed system-wide)
    # ─────────────────────────────────────────────────────────────────────────

    # Note: Steam, gamemode, and related system packages in configuration.nix
    steamcmd
    steam-tui
    mangohud
    protontricks
    minigalaxy # GOG
    itch # Itch.io
    # heroic                              # Epic/GOG/Amazon
    cemu # Wii U emulator
    dosbox # DOS
    limo # Alternative launcher
    wineWowPackages.staging # Wine staging (32/64bit, preferred for gaming)
    winetricks # Wine configuration

    # ─────────────────────────────────────────────────────────────────────────
    # VIEWERS - Media consumption
    # ─────────────────────────────────────────────────────────────────────────

    loupe
    gthumb # Image viewers
    mpv
    vlc
    celluloid # Video players
    spotify
    rhythmbox # Music players
    zathura # PDF viewer

    # ─────────────────────────────────────────────────────────────────────────
    # EDITORS - Image/document editing
    # ─────────────────────────────────────────────────────────────────────────

    gimp
    inkscape
    krita
    darktable
    picard
    easytag
    soundconverter # Audio tagging

    # ─────────────────────────────────────────────────────────────────────────
    # PRODUCERS - Video/audio production
    # ─────────────────────────────────────────────────────────────────────────

    obs-studio
    obs-studio-plugins.wlrobs
    obs-studio-plugins.obs-pipewire-audio-capture
    # kdePackages.kdenlive             # Temporarily disabled - ffmpeg build issues
    # handbrake                        # Temporarily disabled - ffmpeg build issues
    # ffmpeg                           # Temporarily disabled - GCC 15 build issues

    # Music production
    ardour
    lmms
    surge-XT
    vital
    calf
    lsp-plugins
    qsynth
    carla
    easyeffects
    helvum
    qpwgraph

    # ─────────────────────────────────────────────────────────────────────────
    # GAMEDEV - Game development
    # ─────────────────────────────────────────────────────────────────────────

    unityhub
    blender
    pince
    scanmem # Memory editing

    # ─────────────────────────────────────────────────────────────────────────
    # COMMUNICATION - Web, chat, office
    # ─────────────────────────────────────────────────────────────────────────

    firefox
    chromium
    discord
    element-desktop
    signal-desktop
    thunderbird
    geary
    onlyoffice-desktopeditors
    libreoffice-fresh
    obsidian

    # ─────────────────────────────────────────────────────────────────────────
    # SYSADMIN - System administration tools
    # ─────────────────────────────────────────────────────────────────────────

    iotop
    lsof
    strace
    tcpdump
    nmap
    ncdu
    duf
    android-tools
    scrcpy
    gparted-full
    stress-ng
    cava
  ];

  # ════════════════
  # DESKTOP ENVIRONMENT CONFIGURATION
  # ════════════════

  # Hyprland compositor
  # package must match the system-level programs.hyprland package to avoid
  # two different Hyprland versions fighting over the socket.
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = false; # UWSM handles session management (conflicts otherwise)
    extraConfig = ''
      # Custom monitor resolution for older non-SmartTV (1368x768@59.85Hz)
      monitor=HDMI-A-1,1368x768@59.85,0x0,1

      # Gamescope/Steam compatibility (fixes Vulkan issues when running inside Hyprland)
      debug {
        full_cm_proto = true
      }

      # Startup applications (packages installed via Home Manager)
      exec-once = dunst &
      exec-once = /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 &
      exec-once = blueman-applet &
      exec-once = waybar &
      exec-once = hyprpaper &
      exec-once = iwgtk --tray &

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

  # ════════════════
  # PROGRAM CONFIGURATION
  # ════════════════

  # VS Code extensions and settings
  # NOTE: VSCode binary installed via home.packages
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
        identityFile = osConfig.age.secrets."ssh_key_github".path;
        identitiesOnly = true;
      };
      "hobbs" = {
        hostname = "144.202.50.58";
        user = "matt";
        identityFile = osConfig.age.secrets."ssh_key_hobbs".path;
        identitiesOnly = true;
      };
      "hallpass" = {
        hostname = "136.244.101.171";
        user = "matt";
        identityFile = osConfig.age.secrets."ssh_key_hallpass".path;
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

  # Direnv - automatic Nix environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
