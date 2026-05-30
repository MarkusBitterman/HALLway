# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/configuration.nix - <DESCRIPTION>                      ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  # ════════════════
  # BOOT
  # ════════════════

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 4;
        memtest86.enable = true;
        edk2-uefi-shell.enable = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 7;
    };

    kernelPackages = pkgs.linuxPackages;
  };

  # ════════════════
  # BASE SYSTEM
  # ════════════════

  networking.hostName = "<HOSTNAME>";
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";

  # ════════════════
  # USERS
  # ════════════════

  users.mutableUsers = false;

  users.users.<USERNAME> = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
    ];
    hashedPasswordFile = config.sops.secrets."user_password".path;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # ═══════════════════════════════════════════════════════════════════════
  # DISPLAY MANAGER
  # greetd + regreet: GTK4 greeter with user list, password entry, session selection
  # ═══════════════════════════════════════════════════════════════════════

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${lib.getExe pkgs.cage} -s -- ${lib.getExe pkgs.regreet}";
        user = "greeter";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    uwsm start hyprland-uwsm.desktop
  '';

  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = "/etc/greetd/background.jpg";
        fit = "Cover";
      };
    };
  };

  # ════════════════
  # WAYLAND / HYPRLAND
  # ════════════════

  programs.hyprland.enable = true;
  programs.uwsm.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = [ "hyprland" ];
  };

  # ════════════════
  # SECURITY
  # ════════════════

  security.polkit.enable = true;
  security.apparmor.enable = true;
  security.rtkit.enable = true;

  # ════════════════
  # AUDIO (PipeWire)
  # ════════════════

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ════════════════
  # PROGRAMS
  # ════════════════

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
}
