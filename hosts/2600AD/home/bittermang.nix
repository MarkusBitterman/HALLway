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
    monitor = "HDMI-A-1,1920x1080@59.85,0x0,1";
    keyboard = "us";
  };

  # Explicit lua config type — overrides the stateVersion-based hyprlang default
  # (home.stateVersion = "25.11" < "26.05" triggers the legacy default warning;
  # setting this here ensures Hyprland is started in lua mode regardless)
  wayland.windowManager.hyprland.configType = "lua";

  home.stateVersion = "25.11";

  # Runtime paths to decrypted sops secrets (NixOS module).
  # These resolve under /run/secrets/<name> at activation time.
  home.sessionVariables = {
    GITHUB_TOKEN_FILE = osConfig.sops.secrets."github_token".path;
    GPG_PRIVATE_KEY_FILE = osConfig.sops.secrets."gpg_key".path;
  };

  # Ensure ~/.local/bin is in PATH (for claude-code, user scripts, etc.)
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ════════════════
  # PACKAGE INSTALLATION
  # ════════════════

  home.packages = with pkgs; [

    # ─────────────────────────────────────────────────────────────────────────
    # CORE - System utilities (universally accessible, no AppArmor enforcement)
    # ─────────────────────────────────────────────────────────────────────────

    curl
    wget
    rsync
    tree
    btop
    tmux
    age
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

    # CLI dev tools
    gh # GitHub CLI
    mercurial
    jq
    ripgrep
    fd
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

    # Lua
    lua-language-server

    # Nix development
    nixd
    nixfmt

    # HTML/Web
    html5validator
    djlint
    sqlite

    # Java
    # jre # jdk #handled now by jetbrains, above?

    # ─────────────────────────────────────────────────────────────────────────
    # DESKTOP - Additional Wayland tools (DOORwayDE provides core Hyprland stack)
    # ─────────────────────────────────────────────────────────────────────────
    # DOORwayDE installs: hyprland, hyprlock, hypridle, hyprpaper, hyprsunset,
    # waybar, rofi, dunst, wlogout, kitty, grim, slurp, satty, cliphist,
    # playerctl, awww, brightnessctl, pamixer, libnotify

    kdePackages.dolphin # File manager (KDE)
    pavucontrol # Audio control
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
    wineWow64Packages.staging # Wine staging (32/64bit) - renamed from wineWowPackages
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
    surge-xt # renamed from surge-XT
    vital
    calf
    lsp-plugins
    qsynth
    carla
    easyeffects
    # helvum removed (unmaintained, vulnerable dep) - use qpwgraph or crosspipe
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
    socat
  ];

  # ════════════════
  # DESKTOP ENVIRONMENT CONFIGURATION
  # ════════════════
  # NOTE: Hyprland, waybar, rofi, dunst, and other DE components are now
  # managed by DOORwayDE module (see doorwayde options above).
  # The module handles: compositor config, keybindings, autostart apps,
  # theming, and all HyDE-derived configurations.

  # ════════════════
  # PROGRAM CONFIGURATION
  # ════════════════

  programs.claude-code.enable = true;

  programs.vscodium = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        jnoortheen.nix-ide
        sumneko.lua
        ms-dotnettools.csharp
        yzhang.markdown-all-in-one
        rust-lang.rust-analyzer
      ];
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "terminal.integrated.defaultProfile.linux" = "zsh";
      };
    };
  };

  # SSH configuration
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
        HostName = "144.202.50.58";
        User = "matt";
        IdentityFile = osConfig.sops.secrets."ssh_key_hobbs".path;
        IdentitiesOnly = "yes";
      };
      "hallpass" = {
        HostName = "136.244.101.171";
        User = "matt";
        IdentityFile = osConfig.sops.secrets."ssh_key_hallpass".path;
        IdentitiesOnly = "yes";
      };
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "Matthew Hall";
      email = "bittermang@duck.com";
    };
    signing = {
      key = "03FA1C7D2F1B6078152F5A06F1C935BB179C4C2C";
      signByDefault = true;
      format = "openpgp";
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
    enableZshIntegration = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
  };

  home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${osConfig.sops.secrets."gpg_key".path}" ]; then
      ${pkgs.gnupg}/bin/gpg --batch --import \
        "${osConfig.sops.secrets."gpg_key".path}" 2>/dev/null || true
    fi
  '';

  # Shell configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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
