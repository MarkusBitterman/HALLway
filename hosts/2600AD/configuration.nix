# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway - Host: 2600AD                                                   ║
# ║  Atari VCS 800 Gaming/Media Workstation                                   ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOT
  # ═══════════════════════════════════════════════════════════════════════════

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages;  # Stable kernel (guaranteed ZFS support)
  boot.resumeDevice = "/dev/mapper/stella";  # Encrypted swap for hibernation

  # ═══════════════════════════════════════════════════════════════════════════
  # ZFS
  # ═══════════════════════════════════════════════════════════════════════════

  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # NETWORKING
  # ═══════════════════════════════════════════════════════════════════════════

  networking.hostId = "ad42069f";  # Required for ZFS
  networking.hostName = "2600AD";

  systemd.network.enable = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };

  networking.firewall.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX
  # ═══════════════════════════════════════════════════════════════════════════

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
  nixpkgs.config.allowUnfree = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # LOCALIZATION
  # ═══════════════════════════════════════════════════════════════════════════

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # ═══════════════════════════════════════════════════════════════════════════
  # ENVIRONMENT
  # ═══════════════════════════════════════════════════════════════════════════

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # XDG portal paths for Home Manager
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  environment.systemPackages = with pkgs; [
    nano
  ];

  fonts.packages = with pkgs; [
    corefonts
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO & BLUETOOTH
  # ═══════════════════════════════════════════════════════════════════════════

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY
  # ═══════════════════════════════════════════════════════════════════════════

  security.polkit.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # PROGRAMS
  # ═══════════════════════════════════════════════════════════════════════════

  programs = {
    mtr.enable = true;
    zsh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SERVICES
  # ═══════════════════════════════════════════════════════════════════════════

  services.openssh.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # USERS (via HALLway roles module)
  # ═══════════════════════════════════════════════════════════════════════════

  roles.users.bittermang = {
    description = "Matthew Hall";
    uid = 1000;

    extraGroups = [
      "wheel"
      "audio"
      "video"
      "input"
      "gamemode"
    ];

    # Package groups - what bittermang DOES
    groups = [
      "core"           # CLI essentials
      "developers"     # Programming tools (vscode, neovim, etc.)
      "desktop"        # Hyprland/Wayland environment
      "viewers"        # Media viewers (mpv, vlc, loupe, spotify)
      "communication"  # Web, chat, office
      # ───────────────────────────────────────────────────────────────────────
      # DISABLED FOR INITIAL INSTALL (ffmpeg builds from source, takes hours)
      # Uncomment after first successful boot:
      # "gaming"       # Steam + gaming tools
      # "editors"      # GIMP, Inkscape, Krita
      # "producers"    # OBS, Kdenlive, Handbrake (pulls ffmpeg)
      # "gamedev"      # Unity, Blender
      # "sysadmin"     # iotop, tcpdump, nmap
    ];

    # One-off packages not in any group
    extraPackages = with pkgs; [
      # Nothing here - use Home Manager for user apps
    ];
  };

  roles.users.guest = {
    description = "Guest Session";
    uid = 1001;
    shell = pkgs.bash;
    isGuest = true;
    guestTmpfsSize = "2G";

    extraGroups = [ "audio" "video" ];

    # Guest gets desktop + viewers only (tmpfs home wiped on reboot)
    groups = [
      "core"           # CLI basics
      "desktop"        # Hyprland environment
      "viewers"        # Media playback (mpv, vlc, spotify)
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM
  # ═══════════════════════════════════════════════════════════════════════════

  system.stateVersion = "25.11";
}
