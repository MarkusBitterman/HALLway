# ╔════════════════╗
# ║  HALLway - Host: 2600AD                                                   ║
# ║  Atari VCS 800 Gaming/Media Workstation                                   ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

{
  config,
  pkgs,
  ...
}:

let
  # HALLpass mesh registry (modules/mesh.nix) — peer IPs, keys, Syncthing IDs
  mesh = config.hallway.mesh;
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

  boot = {
    loader = {
      systemd-boot = {
        configurationLimit = 7;
        memtest86.enable = true;
        edk2-uefi-shell.enable = true;
      };
      timeout = 14;
    };

    kernelPackages = pkgs.linuxPackages; # Stable kernel (guaranteed ZFS support)

    zfs = {
      unsafeAllowHibernation = true;
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

  zramSwap.memoryPercent = 40;

  # ════════════════
  # NETWORKING
  # ════════════════

  networking = {
    hostId = "76fe1b68"; # required for ZFS
    hostName = "2600AD";
    # useNetworkd = true;
    networkmanager.enable = true; # temporary fallback; systemd-networkd migration pending

    # WiFi via iwd with systemd-networkd (future):
    # wireless.iwd = {
    #   enable = true;
    #   settings.DriverQuirks.DefaultInterface = true;
    # };

    # ─────────────────────────────────────────────────────────────────────────
    # DNS (AdGuard public resolvers)
    # ─────────────────────────────────────────────────────────────────────────
    nameservers = [
      "94.140.14.14"
      "94.140.15.15"
      "2a10:50c0::ad1:ff"
      "2a10:50c0::ad2:ff"
    ];

    # ─────────────────────────────────────────────────────────────────────────
    # HALLpass overlay network (WireGuard)
    # ─────────────────────────────────────────────────────────────────────────
    # Peer registry lives in modules/mesh.nix (hallway.mesh).
    #
    # firewall.checkReversePath = "loose"; # Required for WireGuard rpfilter

    wireguard.interfaces.wg-hallpass = {
      ips = [ "${mesh.hosts.desktop.wgIp}/24" ];
      privateKeyFile = config.sops.secrets."wg_privatekey".path;

      peers = [
        {
          publicKey = mesh.hosts.hallpass.wgPublicKey;
          presharedKeyFile = config.sops.secrets."wg_psk".path;
          endpoint = mesh.hub.endpoint;
          allowedIPs = [ mesh.subnet ];
          persistentKeepalive = 25;
        }
      ];
    };

    firewall.interfaces.wg-hallpass = {
      allowedTCPPorts = [ mesh.syncthingPort ];
      allowedUDPPorts = [ mesh.syncthingPort ];
    };
  };

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

  # ════════════════
  # NIX
  # ════════════════

  # Substitute until nixpkgs fixes afdko/otfautohint breakage in cantarell-fonts-0.311
  nixpkgs = {
    overlays = [
      (final: prev: {
        cantarell-fonts = prev.liberation_ttf;
      })
      # Skip soundconverter's test suite: tests/test.py crashes with
      # `TypeError: 'NoneType' object is not subscriptable` under the
      # Python 3.14 default interpreter (nixos-unstable, 2026-07-08 bump).
      # Upstream test bug, not a soundconverter runtime issue.
      # Note: buildPythonApplication renames the check-phase toggle to
      # `doInstallCheck` internally — plain `doCheck` is a no-op here.
      (final: prev: {
        soundconverter = prev.soundconverter.overrideAttrs (old: {
          doInstallCheck = false;
        });
      })
    ];
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  # Sign all locally-built store paths so HALLpass.space can verify them.
  nix.settings.secret-key-files = [ config.sops.secrets."nix_signing_key".path ];

  # ════════════════
  # LOCALIZATION
  # ════════════════

  time.timeZone = "America/Chicago";

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

  # NO SLEEP ON THIS HARDWARE (Atari VCS 800, BIOS 05.32.50.0011-VCS.24).
  # Verified 2026-07-10 — every path is broken at the platform level:
  #   - S3 ("deep"): firmware bounces straight back out ~2s after entry with
  #     no wake cause recorded anywhere (SCI/GPE/fixed-event counters all 0,
  #     no wakeup source credited). Not a wake-source problem — the Logitech
  #     receiver theory of 2026-07-03 was a red herring (battery events were
  #     a symptom of each resume, not the cause).
  #   - s2idle: amdgpu rejects it ("Unsupported suspend state 1", EINVAL)
  #     because the BIOS advertises S3-style sleep; suspend fails outright.
  #   - hibernate: image allocation fails with ENOMEM (8 GB RAM + zram
  #     inflate the snapshot past free memory); session is never saved.
  # DOORway's idle chain therefore ends at DPMS off (doorway.idle.timeouts
  # .suspend defaults to null). Do not re-add HibernateDelaySec or wake-source
  # udev rules without first fixing sleep at the firmware level (a BIOS
  # sleep-mode toggle to s2idle, if one exists, would be the starting point).

  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";

    # XDG portal paths for Home Manager
    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    systemPackages = with pkgs; [
      # System essentials
      nano
      gcc
      python314Packages.numpy

      # Themes
      tela-icon-theme
      oreo-cursors-plus

      # System tools
      sshfs

      # Android tools, SDK, NDK
      android-tools
      (androidenv.composeAndroidPackages {
        platformVersions = [
          "34"
          "33"
        ];
        abiVersions = [
          "x86_64"
          "arm64-v8a"
        ];
        buildToolsVersions = [ "34.0.0" ];
        includeNDK = true;
      }).androidsdk

      # Unity development
      dotnet-sdk_8
      mono
      # Note: Steam provided by programs.steam.enable (includes steam-run)
    ];
  };

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

  # ════════════════
  # PROGRAMS
  # ════════════════

  programs = {
    mtr.enable = true;
    # Hyprland session registration, UWSM, XWayland, and xdg-desktop-portal-hyprland
    # are managed by DOORway's nixosModules.default (imported in flake.nix).
    # The Hyprland version is pinned in DOORway's flake.lock.
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
      capSysNice = false;
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

  services = {
    syncthing = {
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
            id = mesh.hosts.hallpass.syncthingId;
            addresses = [
              "tcp://${mesh.hosts.hallpass.wgIp}:${toString mesh.syncthingPort}"
              "quic://${mesh.hosts.hallpass.wgIp}:${toString mesh.syncthingPort}"
            ];
            introducer = true;
          };

          Nintendo64 = {
            id = mesh.hosts.phone.syncthingId;
            addresses = [
              "tcp://${mesh.hosts.phone.wgIp}:${toString mesh.syncthingPort}"
              "quic://${mesh.hosts.phone.wgIp}:${toString mesh.syncthingPort}"
            ];
          };
        };

        folders = {
          Documents = {
            id = "Documents";
            path = "/home/bittermang/Documents";
            devices = [
              "Nintendo64"
              "hallpass"
            ];
            type = "sendreceive";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
          };
        };

        options = {
          globalAnnounceEnabled = true;
          globalAnnounceServers = [
            "https://${mesh.hosts.hallpass.wgIp}:${toString mesh.hub.discoveryPort}/?id=${mesh.hub.discoveryId}"
          ];
          localAnnounceEnabled = false;
          natEnabled = false;
          relaysEnabled = true;
          listenAddresses = [
            "default"
            "relay://${mesh.hosts.hallpass.wgIp}:${toString mesh.hub.relayPort}/?id=${mesh.hub.relayId}"
          ];
        };
      };
    };
  };

  # ════════════════
  # USERS (direct NixOS + Home Manager)
  # ════════════════

  users.users = {
    bittermang = {
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

    guest = {
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
