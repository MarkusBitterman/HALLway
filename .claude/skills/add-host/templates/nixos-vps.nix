# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/<HOSTNAME>/configuration.nix - <DESCRIPTION>                      ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  # ═════════════════════════════════════════════════════════════════════════
  # BOOT
  # ═════════════════════════════════════════════════════════════════════════

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ═════════════════════════════════════════════════════════════════════════
  # BASE SYSTEM
  # ═════════════════════════════════════════════════════════════════════════

  networking.hostName = "<HOSTNAME>";
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap.enable = true;
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";

  # ═════════════════════════════════════════════════════════════════════════
  # SECURITY HARDENING
  # ═════════════════════════════════════════════════════════════════════════

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowedUDPPorts = [
      51820 # WireGuard
    ];
  };

  # ═════════════════════════════════════════════════════════════════════════
  # USERS
  # ═════════════════════════════════════════════════════════════════════════

  users.mutableUsers = false;

  users.users.<USERNAME> = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [
      # TODO: add authorized SSH public keys
    ];
    shell = pkgs.bash;
  };

  # ═════════════════════════════════════════════════════════════════════════
  # WIREGUARD HUB
  # ═════════════════════════════════════════════════════════════════════════

  networking.wireguard.interfaces."wg0" = {
    ips = [ "10.23.11.1/24" ]; # TODO: adjust subnet if needed
    listenPort = 51820;
    privateKeyFile = config.sops.secrets."wg_privatekey".path;
    peers = [
      # TODO: add WireGuard peers
      # {
      #   publicKey = "PEER_PUBLIC_KEY";
      #   allowedIPs = [ "10.23.11.X/32" ];
      # }
    ];
  };

  # ═════════════════════════════════════════════════════════════════════════
  # NGINX (reverse proxy / web)
  # ═════════════════════════════════════════════════════════════════════════

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "bittermang@duck.com";
  };

  # ═════════════════════════════════════════════════════════════════════════
  # PACKAGES
  # ═════════════════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    curl
    wget
  ];
}
