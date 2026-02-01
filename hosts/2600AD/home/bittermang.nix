# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway v0.0.1 (2600AD)                                                  ║
# ║  home/bittermang.nix - User Environment Configuration                     ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# This file configures the USER ENVIRONMENT via Home Manager.
#
# Separation of concerns:
#   - roles.users.bittermang.groups (system) → CLI essentials + Steam
#   - This file (Home Manager)               → ALL user apps + dotfiles
#
# Why: Home Manager gives us dotfile control and per-user configuration.
# Exception: Steam stays system-level due to FHS env + 32-bit lib requirements.
#
# ═══════════════════════════════════════════════════════════════════════════════

{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";

  # ═══════════════════════════════════════════════════════════════════════════
  # USER PACKAGES (Everything except Steam)
  # ═══════════════════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # Development
    gh                        # GitHub CLI
    neovim
    vscode
    rustup
    jq
    ripgrep
    fd
    btop

    # Gaming (non-Steam)
    steamcmd
    steam-tui
    minigalaxy                # GOG
    itch
    heroic                    # Epic/GOG/Amazon
    retroarch
    winetricks
    protontricks

    # Desktop/Wayland
    kitty
    pcmanfm
    rofi
    waybar
    dunst
    hyprpaper
    pavucontrol
    polkit_gnome

    # Images
    loupe                     # GNOME viewer
    gthumb
    gimp
    inkscape
    krita
    darktable
    imagemagick

    # Music
    spotify
    rhythmbox
    playerctl
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
    picard                    # MusicBrainz
    easytag
    soundconverter

    # Video
    mpv
    vlc
    celluloid
    obs-studio
    obs-studio-plugins.wlrobs
    obs-studio-plugins.obs-pipewire-audio-capture
    kdePackages.kdenlive
    shotcut
    handbrake
    ffmpeg

    # Web & Communication
    firefox
    chromium
    discord
    element-desktop
    signal-desktop

    # Office & Productivity
    onlyoffice-desktopeditors
    obsidian
    zathura

    # Game Development
    unityhub
    blender
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # DESKTOP ENVIRONMENT CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════

  # Hyprland compositor
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Custom monitor resolution for older non-SmartTV (1368x768@59.85Hz)
      monitor=HDMI-A-1,1368x768@59.85,0x0,1

      # Startup applications (packages installed via home.packages)
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
  # NOTE: VSCode binary installed via home.packages above
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
    matchBlocks = {
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
    userName = "Matthew Hall";
    userEmail = "bittermang@duck.com";
    signing = {
      key = null;  # Set after GPG setup
      signByDefault = false;
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

  # ═══════════════════════════════════════════════════════════════════════════
  # HOME MANAGER MANAGED PACKAGES
  # Only packages that REQUIRE Home Manager configuration go here.
  # Everything else should be in roles.users.bittermang.groups
  # ═══════════════════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # VS Code needs this wrapper for extensions
    (vscode-with-extensions.override {
      vscode = pkgs.vscode;
      vscodeExtensions = config.programs.vscode.extensions;
    })

    # XDG portal (required by Home Manager for portal config)
    xdg-desktop-portal-hyprland
  ];
}
