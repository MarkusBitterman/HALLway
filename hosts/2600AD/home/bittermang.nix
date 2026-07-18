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
  imports = [ inputs.doorway.homeManagerModules.default ];

  # ════════════════
  # DOORway DESKTOP ENVIRONMENT
  # ════════════════
  doorway = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@100,0x0,1";
    keyboard = "us";
    # DOORway Lock: QuickShell shader-screensaver lock (signal-cutout intro,
    # retro-CRT shader suite). Falls back to hyprlock if the shell is down.
    lock.backend = "doorway-lock";
    # Session preservation, layer 2 (layer 1 is hibernation — see the
    # HIBERNATION RESCUE block in ../configuration.nix): snapshot running
    # apps every 2 min, reopen them on their workspaces at next login.
    # Covers real reboots, which hibernation by definition can't.
    session.restore = true;
    # cursor.package defaults to pkgs.oreo-cursors-plus.
    # cursor.name selects which of the 38 variants to use.
    # cursor.size defaults to 24. Omit this block to keep the DOORway default.
    cursor.name = "oreo_spark_neon_pink_bordered_cursors";
    cursor.size = 36;
    # Fonts scaled for a 20" 1080p monitor viewed from several feet.
    # Atkinson Hyperlegible: designed by the Braille Institute for maximum
    # letter-distinction at a distance (0/O, l/I/1 never ambiguous). Already
    # used on MarkusBitterman.github.io as the code font.
    # JetBrains Mono is already available via DOORway deps (bar/interface font).
    fonts.ui.name = "Atkinson Hyperlegible";
    fonts.ui.size = 15;
    fonts.monospace.name = "JetBrainsMono Nerd Font Mono";
    fonts.monospace.size = 13;

    # Cyberpunk/wizard aesthetic:
    # Organic-but-edgy corners — not phone-UI soft, not razor sharp.
    theme.rounding = 14;
    # Tighter inner gap so the glowing borders are the visual frame,
    # generous outer gap so the wallpaper breathes behind everything.
    theme.gapsIn = 4;
    theme.gapsOut = 18;
    # Thick border — matugen paints these with wallpaper accent neons.
    # At 4px the animated border glow is unmissable from across the room.
    theme.borderSize = 4;
    # High-quality blur — lets the neon wallpaper bleed through surfaces.
    theme.blur.size = 8;
    theme.blur.passes = 4;

    # Lean into translucency: wallpaper neons show through windows.
    # Active is still legible from a distance; inactive floats in the glow.
    input.activeOpacity = 0.88;
    input.inactiveOpacity = 0.70;

    # LimeFrenzy: overshot spring on open/close + borderangle loop.
    # The looping animated border is the centrepiece of the cyberpunk look —
    # it continuously rotates the matugen accent gradient around each window.
    animations.preset = "LimeFrenzy";

    # Anurati — space/sci-fi typeface, retro-futuristic. Suits the Atari VCS.
    lock.layout = "Anurati";

    # iwgtk (already in home.packages below) is the WiFi frontend here;
    # nm-applet would be redundant and confusing in the tray.
    networkApplet.enable = false;

    # PirateWeather widget — shows current temp in bar, hourly in popup.
    # Prereq: add a sops secret named "pirate_weather_api_key" whose decrypted
    # content is exactly:  PIRATE_WEATHER_API_KEY=<your_key>
    # Then: sops.secrets."pirate_weather_api_key" = { owner = "bittermang"; };
    weather.enable = true;
    weather.zipCode = "52240";
    weather.updateFrequency = 15;
    weather.pirateWeatherApiKeyFile = osConfig.sops.secrets."pirate_weather_api_key".path;

    # HALLway mark (dolly-zoom H) as the top-left sidebar button icon.
    bar.topLeftIcon = "hallway";

    # Night light follows actual sunrise/sunset from PirateWeather.
    # Iowa City sunset ranges from ~5:15 PM (Dec) to ~8:45 PM (Jun) — a 3.5-hour
    # swing that makes any fixed schedule wrong half the year.
    blueLight.schedule.useWeatherTimes = true;
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
    # DESKTOP - Additional Wayland tools (DOORway provides core Hyprland stack)
    # ─────────────────────────────────────────────────────────────────────────
    # DOORway installs: hyprland, hyprlock, hypridle, hyprpaper, hyprsunset,
    # waybar, rofi, dunst, wlogout, kitty, grim, slurp, satty, cliphist,
    # playerctl, awww, brightnessctl, pamixer, libnotify

    kdePackages.dolphin # File manager (KDE)
    pavucontrol # Audio control
    polkit_gnome # Authentication agent
    iwgtk # WiFi manager (iwd frontend, Wayland tray)
    atkinson-hyperlegible # UI font (doorway.fonts.ui.name = "Atkinson Hyperlegible")

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
  # managed by DOORway module (see doorway options above).
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
      "hallpass hallpass.space" = {
        HostName = "136.244.101.171";
        Port = 2222;
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

    shellAliases = {
      qqq = "exit"; # quick exit

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";

      # ls
      ll = "ls -lh";
      la = "ls -lAh";

      # git
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";

      # misc
      grep = "grep --color=auto";
      c = "clear";
    };
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
