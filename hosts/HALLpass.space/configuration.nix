# ╔════════════════╗
# ║  HALLway - Host: HALLpass.space                                           ║
# ║  VPS Introducer Node — WireGuard hub, Syncthing relay, web front          ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{ config, pkgs, ... }:

let
  # HALLpass mesh registry (modules/mesh.nix) — peer IPs, keys, Syncthing IDs
  mesh = config.hallway.mesh;

  wgIf = "wg-hallspace";

  serverPrivKeyFile = config.sops.secrets."wg_privatekey".path;

  # ── User dotfiles (managed without Home Manager) ─────────────────────────
  # sops-nix deploys secrets to /run/secrets/<name> by default.
  sshConfig = pkgs.writeText "matt-ssh-config" ''
    Host *
      AddKeysToAgent yes

    Host github.com
      HostName github.com
      User git
      IdentityFile /run/secrets/ssh_key_github
      IdentitiesOnly yes
  '';

  gitConfig = pkgs.writeText "matt-gitconfig" ''
    [user]
      name = Matthew Hall
      email = bittermang@duck.com
  '';

  guiPassFile = config.sops.secrets."syncthing_gui_pass".path;

  # ── ACME / TLS ─────────────────────────────────────────────────────────────
  # File must contain: VULTR_API_KEY=<your-api-key>
  acmeCredFile = config.sops.secrets."acme_vultr_api_key".path;

  # ── Mercurial web server ───────────────────────────────────────────────────
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

  # Shared baseline (modules/base.nix): systemd-boot + EFI vars, zram, flakes,
  # locale, firewall, AppArmor, OpenSSH, zsh. Only host-specific settings and
  # overrides below.

  # ════════════════
  # BOOT
  # ════════════════

  boot.kernelPackages = pkgs.linuxPackages_latest; # latest for VPS hardware compat; hardening via sysctl + security.*

  # ════════════════
  # BASE SYSTEM
  # ════════════════

  networking = {
    hostName = "hallpass";
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    # Accept store paths signed by 2600AD's Nix signing key.
    extra-trusted-public-keys = [
      "hallway-2600AD-1:rvtwr8Jr9wex7ztumxgymRCpBempIhzlAfPoEE8vDsI="
    ];
  };
  nixpkgs.config.allowUnfree = false;

  # Strip NixOS documentation tools from the default closure.
  # These pull in w3m, groff, texinfo, libX11, fontconfig, and the full
  # GTK/cairo stack — none of which belong on a headless VPS.
  environment.defaultPackages = [ ];

  # ════════════════
  # SECURITY HARDENING
  # ════════════════

  # ─────────────────────────────────────────────────────────────────────────
  # Kernel hardening
  # ─────────────────────────────────────────────────────────────────────────

  # Blacklist protocols not used on this host — common CVE surface
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];

  boot.kernel.sysctl = {
    # ── Kernel / memory ──────────────────────────────────────────────────
    "kernel.dmesg_restrict" = 1; # non-root cannot read kernel ring buffer
    "kernel.kptr_restrict" = 2; # hide kernel symbol addresses in /proc
    "kernel.yama.ptrace_scope" = 2; # only admins may ptrace
    "kernel.unprivileged_bpf_disabled" = 1; # restrict BPF to root
    "net.core.bpf_jit_harden" = 2; # constant blinding for BPF JIT

    # ── Network ───────────────────────────────────────────────────────────
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1; # log invalid source-route packets
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
    "net.ipv4.tcp_rfc1337" = 1; # TIME_WAIT assassination protection
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  services.openssh = {
    ports = [ 2222 ];
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

  security = {
    protectKernelImage = true; # prevent /dev/mem and live kernel patching
    apparmor.enable = true;

    # ─────────────────────────────────────────────────────────────────────────
    # ACME / TLS
    # ─────────────────────────────────────────────────────────────────────────
    # Single wildcard cert covers hallpass.space and all current/future subdomains.
    # DNS-01 challenge: lego creates a TXT record via Vultr API — no A record needed.
    # group = "nginx" required when using useACMEHost — enableACME would set this automatically.
    acme = {
      acceptTerms = true;
      defaults = {
        email = "bittermang@duck.com";
        dnsProvider = "vultr";
        environmentFile = acmeCredFile;
      };
      certs."hallpass.space" = {
        domain = "*.hallpass.space";
        extraDomainNames = [ "hallpass.space" ];
        group = "nginx";
      };
    };
  };

  networking.firewall = {
    # Internet-facing: SSH (non-default port), HTTP/S, WireGuard only.
    allowedTCPPorts = [
      2222
      80
      443
    ];
    allowedUDPPorts = [ mesh.wgPort ];

    # Syncthing infra (and its GUI) should only be reachable over WireGuard.
    interfaces.${wgIf} = {
      allowedTCPPorts = [
        mesh.syncthingPort
        mesh.hub.relayPort
        mesh.hub.relayStatusPort
        mesh.hub.discoveryPort
        8384 # Syncthing GUI
      ];
      allowedUDPPorts = [ mesh.syncthingPort ];
    };
  };

  # ════════════════
  # USERS
  # ════════════════

  users.users = {
    matt = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      createHome = true;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYLaLlzDGnQQ7lVr5jlGRjudWfdhtGl1mEkoFXq2eCc matt@hallpass.space"
      ];
    };
  };

  # ═════════════════════════════════════════════════════════════════════════
  # WIREGUARD HUB
  # ═════════════════════════════════════════════════════════════════════════

  networking.wireguard.interfaces.${wgIf} = {
    ips = [ "${mesh.hosts.hallpass.wgIp}/24" ];
    listenPort = mesh.wgPort;
    privateKeyFile = serverPrivKeyFile;

    peers = [
      {
        publicKey = mesh.hosts.desktop.wgPublicKey;
        presharedKeyFile = config.sops.secrets."wg_desktop_psk".path;
        allowedIPs = [ "${mesh.hosts.desktop.wgIp}/32" ];
      }
      {
        publicKey = mesh.hosts.phone.wgPublicKey;
        # presharedKeyFile = config.sops.secrets."wg_phone_psk".path;  # TODO: generate phone PSK
        allowedIPs = [ "${mesh.hosts.phone.wgIp}/32" ];
      }
    ];
  };

  # ═════════════════════════════════════════════════════════════════════════
  # SYNCTHING INTRODUCER + PRIVATE INFRA
  # ═════════════════════════════════════════════════════════════════════════

  services.syncthing = {
    enable = true;
    guiAddress = "${mesh.hosts.hallpass.wgIp}:8384"; # WireGuard interface only — never bind 0.0.0.0 here
    guiPasswordFile = guiPassFile;
    dataDir = "/var/lib/syncthing";
    configDir = "/var/lib/syncthing/config";
    databaseDir = "/var/lib/syncthing/db";
    overrideFolders = true;
    overrideDevices = false;

    settings = {
      devices = {
        desktop = {
          id = mesh.hosts.desktop.syncthingId;
          addresses = [
            "tcp://${mesh.hosts.desktop.wgIp}:${toString mesh.syncthingPort}"
            "quic://${mesh.hosts.desktop.wgIp}:${toString mesh.syncthingPort}"
          ];
        };
      };

      folders = {
        Documents = {
          id = "Documents";
          path = "/home/matt/Documents";
          devices = [ "desktop" ];
          type = "sendreceive";
          versioning = {
            type = "simple";
            params.keep = "5";
          };
        };
      };

      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = false;
      };
    };

    relay = {
      enable = true;
      pools = [ ];
      listenAddress = mesh.hosts.hallpass.wgIp;
      statusListenAddress = mesh.hosts.hallpass.wgIp;
      port = mesh.hub.relayPort;
      statusPort = mesh.hub.relayStatusPort;
      providedBy = "hallpass.space";
    };
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
          --listen=${mesh.hosts.hallpass.wgIp}:${toString mesh.hub.discoveryPort} \
          --db-dir=/var/lib/syncthing-discovery/db \
          --cert=/var/lib/syncthing-discovery/cert.pem \
          --key=/var/lib/syncthing-discovery/key.pem
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
    "d /srv/www/hallpass.space/_public 0755 matt users -"
    "d /srv/hg/repos          0755 matt users -"
    # User dotfile management (replaces Home Manager)
    "d  /home/matt/.ssh               0700 matt users -"
    "L+ /home/matt/.ssh/config        -    -    -     - ${sshConfig}"
    "L+ /home/matt/.gitconfig         -    -    -     - ${gitConfig}"
    # /home/matt defaults to 0700, which blocks the "syncthing" user from even
    # traversing into it — grant search-only access without exposing directory listing.
    "d  /home/matt                    0711 matt users -"
    # Syncthing (runs as the dedicated "syncthing" user) needs group access to write here
    "d  /home/matt/Documents          0775 matt syncthing -"
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

    # Static site — place files in /srv/www/hallpass.space/_public/
    virtualHosts."hallpass.space" = {
      useACMEHost = "hallpass.space"; # cert managed in SECURITY HARDENING
      forceSSL = true;
      root = "/srv/www/hallpass.space/_public";
      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };

    # Mercurial web interface — repos at /srv/hg/repos/<name>/
    virtualHosts."hg.hallpass.space" = {
      useACMEHost = "hallpass.space"; # cert managed in SECURITY HARDENING
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString hgPort}";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    syncthing
    mercurial
    jq
    age
    ssh-to-age
    # Operator / user tools (previously in home/matt.nix)
    curl
    wget
    tmux
    git
    htop
    ncdu
    lsof
  ];

  system.stateVersion = "26.05";
}
