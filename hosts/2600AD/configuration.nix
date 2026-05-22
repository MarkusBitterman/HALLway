# ╔════════════════╗
# ║  HALLway - Host: 2600AD                 ║
# ║  Atari VCS 800 Gaming/Media Workstation                                   ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{
  config,
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
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 7;
    };

    kernelPackages = pkgs.linuxPackages; # Stable kernel (guaranteed ZFS support)

    zfs = {
      # allowHibernation = true;
      # renamed to unsafeAllowHibernation in NixOS 26.05 - commented to test behavior
    };

    resumeDevice = "/dev/mapper/stella_crypt"; # Encrypted swap for hibernation

    plymouth = {
      enable = true;
      theme = "bgrt";
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };

  # ════════════════
  # ZFS
  # ════════════════

  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 80;
  };

  # ════════════════
  # NETWORKING
  # ════════════════

  networking.hostId = "76fe1b68"; # Required for ZFS
  networking.hostName = "2600AD";
  # networking.useNetworkd = true;
  networking.networkmanager.enable = true; # iwd + systemd-networkd instead; GNOME would enable this implicitly; we have enabled it implicitly becuase attemnpting to switch to NetworkD has not gone well

  # WiFi managed by iwd; DHCP handed to systemd-networkd
  # networking.wireless.iwd = {
  #  enable = true;
  #  settings.DriverQuirks.DefaultInterface = true;
  #};

  # ─────────────────────────────────────────────────────────────────────────
  # DNS (AdGuard public resolvers)
  # ─────────────────────────────────────────────────────────────────────────
  networking.nameservers = [
    "94.140.14.14"
    "94.140.15.15"
    "2a10:50c0::ad1:ff"
    "2a10:50c0::ad2:ff"
  ];

  # ─────────────────────────────────────────────────────────────────────────
  # HALLpass overlay network (WireGuard)
  # ─────────────────────────────────────────────────────────────────────────
  # Subnet: 10.23.11.0/24
  #   - HALLpass.space (hub):  10.23.11.1
  #   - 2600AD (this host):    10.23.11.80
  #   - HelloMoto (phone):     10.23.11.64
  #
  # NOTE: Using IP endpoint instead of hostname avoids DNS chicken-and-egg
  # when routing DNS through the tunnel. Get VPS IP with: dig +short hallpass.space
  #
  # networking.firewall.checkReversePath = "loose"; # Required for WireGuard rpfilter
  #
  # networking.wireguard.interfaces.wg-hallpass = {
  #   ips = [ "10.23.11.80/24" ];
  #   privateKeyFile = config.sops.secrets."wg_privatekey".path;
  #
  #   peers = [
  #     {
  #       publicKey = "894D+6bHWTBC3CXPbtn9Nv/hTnk+vOnd0PrshTPMxQo=";
  #       presharedKeyFile = config.sops.secrets."wg_psk".path;
  #       endpoint = "hallpass.space:51820"; # TODO: replace with IP once VPS is deployed
  #       allowedIPs = [ "10.23.11.0/24" ];
  #       persistentKeepalive = 25;
  #     }
  #   ];
  # };

  # Don't block boot waiting for ALL interfaces — any one coming up is enough.
  systemd.network.wait-online.anyInterface = true;

  # systemd.network = {
  #   enable = true;
  #
  #   networks."10-lan" = {
  #     matchConfig.Name = "en*";
  #     networkConfig.DHCP = "yes";
  #   };
  #
  #   networks."20-wifi" = {
  #     matchConfig.Name = "wl*";
  #     networkConfig.DHCP = "yes";
  #     # Don't fail activation if WiFi isn't connected at boot
  #     linkConfig.RequiredForOnline = "no";
  #   };
  # };

  networking.firewall = {
    enable = true;
    interfaces.wg-hallpass = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
    };
  };

  # ════════════════
  # NIX
  # ════════════════

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nixpkgs.config.allowUnfree = true;

  # ════════════════
  # LOCALIZATION
  # ════════════════

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # ═══════════════════════════════════════════════════════════════════════════
  # DISPLAY MANAGER (greetd + regreet - Wayland-native)
  # ═══════════════════════════════════════════════════════════════════════════
  # regreet: GTK4 greeter with user list, password entry, session selection
  # cage: minimal Wayland compositor that runs only the greeter
  # ═══════════════════════════════════════════════════════════════════════════

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
        user = "greeter";
      };
    };
  };

  # regreet configuration
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        fit = "Cover";
        # path = "/path/to/wallpaper.png"; # Optional: add a login wallpaper
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
    };
  };

  # Prevent console spam on greetd TTY
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # ════════════════
  # ENVIRONMENT
  # ════════════════
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    daemon.settings = {
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9323";
      ipv6 = false;
      # fixed-cidr-v6 = "fd00::/80";
    };
  };

  services.udev = {
    enable = true;
    extraRules = ''
      ACTION=="add", SUBSYSTEM=="process", KERNEL=="*", TAG+="gamescope"
    ''; # Allow gamescope to set SCHED_FIFO on game processes for better performance
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # XDG portal paths for Home Manager
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  environment.systemPackages = with pkgs; [
    # System essentials
    nano
    gcc
    python314Packages.numpy

    # Themes
    tela-icon-theme
    oreo-cursors-plus

    # System tools
    sshfs

    # Note: Steam provided by programs.steam.enable (includes steam-run)
  ];

  fonts.packages = with pkgs; [
    corefonts
  ];

  # ════════════════
  # AUDIO & BLUETOOTH
  # ════════════════

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  # services.blueman.enable = true;

  # ════════════════
  # SECURITY
  # ════════════════

  security.polkit.enable = true;
  security.apparmor.enable = true;

  # ════════════════
  # XFCE FALLBACK SESSION
  # ════════════════
  # Stable X11 fallback for debugging Wayland/Hyprland issues.
  # Appears in regreet session dropdown alongside Hyprland.

  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.startx.enable = true; # Don't start X automatically; let greetd handle it
  };

  # ════════════════
  # PROGRAMS
  # ════════════════

  programs = {
    mtr.enable = true;
    zsh.enable = true;
    # Registers the Hyprland session with GDM and enables polkit, XWayland,
    # xdg-desktop-portal-hyprland, and graphics support system-wide.
    hyprland = {
      enable = true;
      withUWSM = true; # Universal Wayland Session Manager (recommended since 24.11)
      xwayland.enable = true;
    };
    nix-ld = {
      enable = true;
      # Libraries exposed to foreign (non-Nix) ELF binaries via nix-ld.
      # Applies to binaries installed outside Nix: uv/pip wheels, rustup
      # toolchain, npm native addons. All Nix-managed packages already have
      # patched RPATHs and do NOT need entries here.
      libraries = with pkgs; [
        # ── C++ runtime (rustup toolchain, numpy, most native wheels) ──────
        stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1

        # ── Python stdlib native-extension deps ────────────────────────────
        zlib # libz.so.1       (compression, nearly universal)
        openssl # libssl/libcrypto (TLS: cryptography, paramiko, requests…)
        libffi # libffi.so.8   (cffi, ctypes bindings)
        ncurses # libncursesw   (readline-based CLIs, Python curses)
        expat # libexpat.so.1 (Python xml.etree, xmlrpc)
        xz # liblzma.so.5   (Python lzma module)
        bzip2 # libbz2.so.1   (Python bz2 module)
        sqlite # libsqlite3    (Python sqlite3 module, many ORMs)

        # ── System / GTK glue (uv-installed GUI/tray tools) ───────────────
        glib # libglib-2.0.so.0

        # ── Linux native game binaries (itch, GOG/minigalaxy) ─────────────
        # Steam/Proton runs inside its own FHS container — the entries below
        # are for pre-built native Linux ELF binaries from itch and minigalaxy
        # that are NOT Nix-wrapped and ARE loaded by the Linux ELF dynamic linker.

        # GPU / rendering
        libGL # OpenGL ICD loader
        libGLU # GLU utility (older pre-builts)
        mesa # DRI/software GL fallback
        vulkan-loader # Vulkan ICD loader (libvulkan.so.1)
        libdrm # DRM/KMS interface (Mesa internal dep)

        # Audio
        alsa-lib # libasound.so.2 (most common audio ABI in pre-built Linux bins)
        libpulseaudio # libpulse.so.0 (PipeWire exposes this ABI on this system)
        libvorbis # Ogg Vorbis decode
        libogg # Ogg container (libvorbis dep)

        # SDL2 game framework (dominant for itch/GOG indie titles)
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf

        # Input / display
        libxkbcommon # keyboard input (X11 + Wayland; SDL2/GLFW dep)
        wayland # Wayland client (SDL2 Wayland backend)

        # Text rendering
        fontconfig # font discovery (libfontconfig.so.1)
        freetype # TrueType/OTF rendering (libfreetype.so.6)
        harfbuzz # text shaping (SDL2_ttf + FreeType dep)

        # System integration
        libuuid # UUID generation (engine save/session systems)
        libxcrypt-legacy # libcrypt.so.1 legacy ABI (pre-2020 pre-built binaries)
        dbus # D-Bus client (itch/minigalaxy launcher IPC)
        libxml2 # libxml2.so.2 (game engines + minigalaxy GTK dep)

        # X11 compatibility (XWayland + pure X11 mode)
        libx11
        libxext
        libxcursor
        libxrandr
        libxi
        libxfixes
        libxrender
        libxinerama # multi-monitor X11 (SDL2 links against it)
        libxcb
        libxcb-image
        libxcb-keysyms
        libxcb-render-util

      ];
    };
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
      gamescopeSession.enable = true; # Separate GDM session (Steam Deck-like)
      protontricks.enable = true;
      extraPackages = with pkgs; [
        freetype # TrueType font rendering (required by some Proton games)
      ];
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      # Note: gamescope provided by programs.gamescope.enable
      # Note: extest removed (X11 input emulation, not needed for pure Wayland)
    };
  };

  # ════════════════
  # SERVICES
  # ════════════════

  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    user = "bittermang";
    group = "users";
    dataDir = "/home/bittermang";
    configDir = "/home/bittermang/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    guiPasswordFile = config.sops.secrets."syncthing_gui_pass".path;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        hallpass = {
          id = "HALLPASS_SYNCTHING_DEVICE_ID";
          addresses = [
            "tcp://10.23.11.1:22000"
            "quic://10.23.11.1:22000"
          ];
          introducer = true;
        };

        Nintendo64 = {
          id = "RNQ46P5-MED5PWA-2UAPW2O-VVA6FUK-34KPUAQ-GAEATTS-ONCPRMN-YKJ77QH";
          addresses = [
            "tcp://10.23.11.64:22000"
            "quic://10.23.11.64:22000"
          ];
        };
      };

      folders = {
        Documents = {
          id = "Documents";
          path = "/home/bittermang/Documents";
          devices = [ "Nintendo64" ];
        };
      };

      options = {
        globalAnnounceEnabled = true;
        globalAnnounceServers = [
          "https://10.23.11.1:8443/?id=DISCOVERY_SERVER_ID"
        ];
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = true;
        listenAddresses = [
          "default"
          "relay://10.23.11.1:22067/?id=RELAY_SERVER_ID"
        ];
      };
    };
  };

  # ════════════════
  # USERS (direct NixOS + Home Manager)
  # ════════════════

  users.users.bittermang = {
    isNormalUser = true;
    description = "Matthew Hall";
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "input"
      "gamemode"
      "kvm"
      "adbusers"
      "docker"
    ];
  };

  users.users.guest = {
    isNormalUser = true;
    description = "Guest Session";
    uid = 1001;
    shell = pkgs.bash;
    extraGroups = [
      "audio"
      "video"
    ];

    # Guest packages remain system-level (tmpfs home is wiped on reboot)
    packages = with pkgs; [
      # Core
      git
      curl
      wget
      btop

      # Desktop
      kitty
      rofi
      pcmanfm
      waybar
      dunst
      hyprpaper
      pavucontrol
      playerctl
      polkit_gnome
      xdg-desktop-portal-hyprland

      # Viewers
      loupe
      mpv
      vlc
      spotify
    ];
  };

  # Guest clean room (ephemeral home)
  fileSystems."/home/guest" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=2G"
      "mode=0700"
      "uid=1001"
      "gid=100"
    ];
  };

  system.activationScripts.guestSkeleton = {
    text = ''
      mkdir -p /home/guest/.config
      mkdir -p /home/guest/Downloads
      mkdir -p /home/guest/Pictures
      mkdir -p /home/guest/Videos
      mkdir -p /home/guest/Music

      if [ -d /etc/skel ]; then
        cp -rn /etc/skel/. /home/guest/ 2>/dev/null || true
      fi

      chown -R guest:users /home/guest
    '';
    deps = [ "users" ];
  };

  # ════════════════
  # SYSTEM
  # ════════════════

  system.stateVersion = "25.11";
}
