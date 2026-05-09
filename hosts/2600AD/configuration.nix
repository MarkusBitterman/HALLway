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
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages; # Stable kernel (guaranteed ZFS support)

    zfs = {
      allowHibernation = true;
      forceImportRoot = false;
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
    loader.timeout = 0;
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

  networking.hostId = "ad42069f"; # Required for ZFS
  networking.hostName = "2600AD";
  networking.useNetworkd = true;
  networking.networkmanager.enable = false; # iwd + systemd-networkd instead; GNOME would enable this implicitly

  # WiFi managed by iwd; DHCP handed to systemd-networkd
  networking.wireless.iwd = {
    enable = true;
    settings.DriverQuirks.DefaultInterface = true;
  };

  # Hallpass overlay network client settings
  networking.wireguard.interfaces.wg-hallspace = {
    ips = [ "10.44.0.2/24" ];
    privateKeyFile = config.age.secrets."wg-2600ad-privatekey".path;

    peers = [
      {
        publicKey = "xVl7ZD5oumSdXDYudc3zip0Zo3draHuniQoYQFNth1M=";
        presharedKeyFile = config.age.secrets."wg-hallspace-psk".path;
        endpoint = "hallpass.space:51820";
        allowedIPs = [ "10.44.0.0/24" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # Don't block boot waiting for ALL interfaces — any one coming up is enough.
  systemd.network.wait-online.anyInterface = true;

  systemd.network = {
    enable = true;

    networks."10-lan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };

    networks."20-wifi" = {
      matchConfig.Name = "wl*";
      networkConfig.DHCP = "yes";
      # Don't fail activation if WiFi isn't connected at boot
      linkConfig.RequiredForOnline = "no";
    };
  };

  networking.firewall = {
    enable = true;
    interfaces.wg-hallspace = {
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

  # ___________________________________________________________________________
  # DISPLAY MANAGER (troubleshooting with Gnome)
  # ___________________________________________________________________________
  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true; # Required for Wayland sessions (including Hyprland) to appear in GDM
    };
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

    # Steam (requires system-level for 32-bit FHS compatibility)
    steam
    steam-run
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
  # PROGRAMS
  # ════════════════

  programs = {
    mtr.enable = true;
    zsh.enable = true;
    # Registers the Hyprland session with GDM and enables polkit, XWayland,
    # xdg-desktop-portal-hyprland, and graphics support system-wide.
    hyprland.enable = true;
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

        # !! IMPORTANT !!
        # everything above this line are libraries included intentionally for wine/proton
        # everything beblow this line comes from NixOS Wiki: Jetbeans Tools
        # and is included continuing to troubleshoot wine/proton edge cases
        # thanks :)

        SDL
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        SDL_image
        SDL_mixer
        SDL_ttf
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        bzip2
        cairo
        cups
        curlWithGnuTls
        dbus
        dbus-glib
        desktop-file-utils
        e2fsprogs
        expat
        flac
        fontconfig
        freeglut
        freetype
        fribidi
        fuse
        fuse3
        gdk-pixbuf
        glew110
        glib
        gmp
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-ugly
        gst_all_1.gstreamer
        gtk2
        harfbuzz
        icu
        keyutils.lib
        libGL
        libGLU
        libappindicator-gtk2
        libcaca
        libcanberra
        libcap
        libclang.lib
        libdbusmenu
        libdrm
        libgcrypt
        libgpg-error
        libidn
        libjack2
        libjpeg
        libmikmod
        libogg
        libpng12
        libpulseaudio
        librsvg
        libsamplerate
        libthai
        libtheora
        libtiff
        libudev0-shim
        libusb1
        libuuid
        libvdpau
        libvorbis
        libvpx
        libxcrypt-legacy
        libxkbcommon
        libxml2
        mesa
        nspr
        nss
        openssl
        p11-kit
        pango
        pixman
        python3
        speex
        tbb
        udev
        vulkan-loader
        wayland
        xorg.libICE
        xorg.libSM
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXft
        xorg.libXi
        xorg.libXinerama
        xorg.libXmu
        xorg.libXrandr
        xorg.libXrender
        xorg.libXt
        xorg.libXtst
        xorg.libXxf86vm
        xorg.libpciaccess
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        xorg.xkeyboardconfig
        xz
        zlib

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
      extest.enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      extraPackages = with pkgs; [
        gamescope
      ];
      extraCompatPackages = with pkgs; [
        proton-ge-bin
        freetype
      ];
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
    guiPasswordFile = config.age.secrets."syncthing-gui-pass".path;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        hallpass = {
          id = "HALLPASS_SYNCTHING_DEVICE_ID";
          addresses = [
            "tcp://10.44.0.1:22000"
            "quic://10.44.0.1:22000"
          ];
          introducer = true;
        };

        Nintendo64 = {
          id = "RNQ46P5-MED5PWA-2UAPW2O-VVA6FUK-34KPUAQ-GAEATTS-ONCPRMN-YKJ77QH";
          addresses = [
            "tcp://10.44.0.3:22000"
            "quic://10.44.0.3:22000"
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
          "https://10.44.0.1:8443/?id=DISCOVERY_SERVER_ID"
        ];
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = true;
        listenAddresses = [
          "default"
          "relay://10.44.0.1:22067/?id=RELAY_SERVER_ID"
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
