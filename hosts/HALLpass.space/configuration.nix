# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  hosts/HALLpass.space/configuration.nix - VPS Introducer Node             ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{ config, pkgs, ... }:

let
  wgIf = "wg-hallspace";
  wgPort = 51820;

  # WireGuard private key via sops-nix
  serverPrivKeyFile = config.sops.secrets."wg_privatekey".path;

  peers = {
    desktop = {
      publicKey = "xVl7ZD5oumSdXDYudc3zip0Zo3draHuniQoYQFNth1M=";
      ip = "10.23.11.80/32";
    };
    phone = {
      publicKey = "PHONE_WG_PUBLIC_KEY";
      ip = "10.23.11.64/32";
    };
  };

  # Syncthing GUI password secret (plaintext file; Syncthing hashes it)
  guiPassFile = config.sops.secrets."syncthing_gui_pass".path;

  # ── ACME / TLS ──────────────────────────────────────────────────────────────
  # Credentials file for lego's Vultr DNS-01 provider.
  # File content (sourced as shell env): VULTR_API_KEY=your-key-here
  acmeCredFile = config.sops.secrets."acme_vultr_api_key".path;

  # ── Mercurial web server ────────────────────────────────────────────────────
  hgPort = 8085;
  hgRepoDir = "/srv/hg/repos";
  hgwebConf = pkgs.writeText "hgweb.conf" ''
    [web]
    style = paper
    allow_read = *
    push_ssl = false

    [paths]
    / = ${hgRepoDir}/**
  '';
in
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

  networking.hostName = "hallpass";
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };

  # Small VPS: no swap file, optimize store usage.
  zramSwap.enable = true;
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = false;

  # ═════════════════════════════════════════════════════════════════════════
  # SECURITY HARDENING
  # ═════════════════════════════════════════════════════════════════════════

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";
      PermitTunnel = "no";
      ClientAliveInterval = 120;
      ClientAliveCountMax = 2;
      AllowUsers = [ "matt" ];
    };
  };

  security.apparmor.enable = true;

  networking.firewall = {
    enable = true;
    # Internet-facing: SSH, HTTP/S, WireGuard only.
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowedUDPPorts = [ wgPort ];

    # Syncthing infra should only be reachable over WireGuard.
    interfaces.${wgIf} = {
      allowedTCPPorts = [
        22000
        22067
        22070
        8443
      ];
      allowedUDPPorts = [ 22000 ];
    };
  };

  # ═════════════════════════════════════════════════════════════════════════
  # USERS
  # ═════════════════════════════════════════════════════════════════════════

  users.users.matt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    createHome = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYLaLlzDGnQQ7lVr5jlGRjudWfdhtGl1mEkoFXq2eCc matt@hallpass.space"
    ];
  };

  programs.zsh.enable = true;

  # ═════════════════════════════════════════════════════════════════════════
  # WIREGUARD HUB
  # ═════════════════════════════════════════════════════════════════════════

  networking.wireguard.interfaces.${wgIf} = {
    ips = [ "10.23.11.1/24" ];
    listenPort = wgPort;
    privateKeyFile = serverPrivKeyFile;

    peers = [
      {
        publicKey = peers.desktop.publicKey;
        presharedKeyFile = config.sops.secrets."wg_desktop_psk".path;
        allowedIPs = [ peers.desktop.ip ];
      }
      {
        publicKey = peers.phone.publicKey;
        # presharedKeyFile = config.sops.secrets."wg_phone_psk".path;  # TODO: generate phone PSK
        allowedIPs = [ peers.phone.ip ];
      }
    ];
  };

  # ═════════════════════════════════════════════════════════════════════════
  # SYNCTHING INTRODUCER + PRIVATE INFRA
  # ═════════════════════════════════════════════════════════════════════════

  services.syncthing = {
    enable = true;
    guiAddress = "127.0.0.1:8384";
    guiPasswordFile = guiPassFile;
    dataDir = "/var/lib/syncthing";
    configDir = "/var/lib/syncthing/config";
    databaseDir = "/var/lib/syncthing/db";
    overrideFolders = true;
    overrideDevices = false;

    settings = {
      folders = { };
      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = false;
      };
    };
  };

  services.syncthing.relay = {
    enable = true;
    pools = [ ];
    listenAddress = "10.23.11.1";
    statusListenAddress = "10.23.11.1";
    port = 22067;
    statusPort = 22070;
    providedBy = "hallpass.space";
  };

  systemd.services.syncthing-discovery = {
    description = "Syncthing Discovery Server (stdiscosrv)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "syncthing-discovery";
      WorkingDirectory = "/var/lib/syncthing-discovery";
      ExecStart = ''
        ${pkgs.syncthing-discovery}/bin/stdiscosrv \
          -listen=10.23.11.1:8443 \
          -db-dir=/var/lib/syncthing-discovery/db \
          -cert=/var/lib/syncthing-discovery/cert.pem \
          -key=/var/lib/syncthing-discovery/key.pem
      '';
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # ═════════════════════════════════════════════════════════════════════════
  # WEB + MERCURIAL
  # ═════════════════════════════════════════════════════════════════════════

  # Persistent directories for static site and Mercurial repos
  systemd.tmpfiles.rules = [
    "d /srv/hallspace/_public 0755 matt users -"
    "d /srv/hg/repos          0755 matt users -"
  ];

  # hgweb serves all repos under /srv/hg/repos/ on loopback.
  # nginx terminates TLS and proxies hg.hallpass.space → here.
  # Push via SSH: hg clone ssh://matt@hallpass.space//srv/hg/repos/<name>
  systemd.services.hgweb = {
    description = "Mercurial web interface (hgweb)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "matt";
      Group = "users";
      ExecStart = "${pkgs.mercurial}/bin/hg serve --webdir-conf ${hgwebConf} --address 127.0.0.1 --port ${toString hgPort}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;

    # Drop requests for unknown vhosts silently
    virtualHosts."_" = {
      default = true;
      locations."/".return = "444";
    };

    # Static site — place files in /srv/hallspace/_public/
    virtualHosts."hallpass.space" = {
      useACMEHost = "hallpass.space";
      forceSSL = true;
      root = "/srv/hallspace/_public";
      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };

    # Mercurial web interface — repos at /srv/hg/repos/<name>/
    virtualHosts."hg.hallpass.space" = {
      useACMEHost = "hallpass.space";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString hgPort}";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "bittermang@duck.com";
      dnsProvider = "vultr";
      # File must contain: VULTR_API_KEY=<your-api-key>
      # (renamed from credentialsFile in NixOS 26.05)
      environmentFile = acmeCredFile;
    };
    # Single wildcard cert covers hallpass.space and all current/future subdomains.
    # DNS-01 challenge: lego creates a TXT record via Vultr API — no A record needed.
    # group = "nginx" required when using useACMEHost — enableACME would set this automatically.
    certs."hallpass.space" = {
      domain = "*.hallpass.space";
      extraDomainNames = [ "hallpass.space" ];
      group = "nginx";
    };
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    syncthing
    mercurial
    jq
    age # age encryption (key operations, sops workflow)
    ssh-to-age # derive age public keys from SSH ed25519 keys
  ];

  system.stateVersion = "26.05";
}
