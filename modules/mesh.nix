# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/mesh.nix - HALLpass mesh registry (WireGuard + Syncthing)        ║
# ╚════════════════╝
#
# Single source of truth for the HALLpass overlay network. Every host reads
# peer addresses, WireGuard public keys, and Syncthing IDs from
# config.hallway.mesh instead of hardcoding the other hosts' values.
#
# Secrets (private keys, PSKs, passwords) never live here — only public
# identifiers. Private material stays in sops (hosts/<host>/secrets.yaml).

{ lib, ... }:

let
  inherit (lib) mkOption types;

  hostOpts = types.submodule {
    options = {
      wgIp = mkOption {
        type = types.str;
        description = "WireGuard overlay IP, without CIDR suffix.";
      };
      wgPublicKey = mkOption {
        type = types.str;
        description = "WireGuard public key.";
      };
      syncthingId = mkOption {
        type = types.str;
        description = "Syncthing device ID.";
      };
    };
  };
in
{
  options.hallway.mesh = {
    # ─────────────────────────────────────────────────────────────────────
    # Overlay network
    # ─────────────────────────────────────────────────────────────────────

    subnet = mkOption {
      type = types.str;
      default = "10.23.11.0/24";
      description = "HALLpass WireGuard overlay subnet.";
    };

    wgPort = mkOption {
      type = types.port;
      default = 51820;
      description = "WireGuard listen port on the hub.";
    };

    syncthingPort = mkOption {
      type = types.port;
      default = 22000;
      description = "Syncthing sync port (TCP + QUIC) on every host.";
    };

    # ─────────────────────────────────────────────────────────────────────
    # Hub (HALLpass.space) infrastructure
    # ─────────────────────────────────────────────────────────────────────

    hub = {
      endpoint = mkOption {
        type = types.str;
        default = "136.244.101.171:51820";
        description = "Public WireGuard endpoint of HALLpass.space (IP, not hostname, to avoid a DNS chicken-and-egg when DNS routes through the tunnel).";
      };

      discoveryPort = mkOption {
        type = types.port;
        default = 8443;
        description = "stdiscosrv listen port on the hub's overlay IP.";
      };

      relayPort = mkOption {
        type = types.port;
        default = 22067;
        description = "strelaysrv listen port on the hub's overlay IP.";
      };

      relayStatusPort = mkOption {
        type = types.port;
        default = 22070;
        description = "strelaysrv status port.";
      };

      # Derived from certs generated on first startup of each service on the
      # hub — see docs/secrets.md.
      discoveryId = mkOption {
        type = types.str;
        default = "5HGZLLW-G57L5ML-MHFXSQS-X42CWXH-U7MEXVO-AQKSJYJ-AE2JZML-NSWINAV";
        description = "Syncthing discovery server (stdiscosrv) device ID.";
      };

      relayId = mkOption {
        type = types.str;
        default = "3A23ZPS-NK2CKB3-VI3RVI4-AAOEO3F-DMNLSA4-OYT6HR4-QRX6V7R-MFPBIQY";
        description = "Syncthing relay server (strelaysrv) ID.";
      };
    };

    # ─────────────────────────────────────────────────────────────────────
    # Host registry
    # ─────────────────────────────────────────────────────────────────────

    hosts = mkOption {
      type = types.attrsOf hostOpts;
      description = "Public identifiers for every HALLpass mesh member.";
      default = {
        # HALLpass.space — VPS hub / introducer
        hallpass = {
          wgIp = "10.23.11.1";
          # Provisional until HALLpass.space is deployed — see docs/secrets.md.
          wgPublicKey = "894D+6bHWTBC3CXPbtn9Nv/hTnk+vOnd0PrshTPMxQo=";
          syncthingId = "C4JN6DN-4PSNYVR-W42VBAN-TZMVJ7A-3BLC7VX-WPO7UIL-G4YZGPU-4JERRAA";
        };

        # 2600AD — Atari VCS 800 workstation
        desktop = {
          wgIp = "10.23.11.80";
          wgPublicKey = "xVl7ZD5oumSdXDYudc3zip0Zo3draHuniQoYQFNth1M=";
          syncthingId = "LOT5SSD-K6IIODI-O5JFTOZ-DQLQJNB-ZCKZK6X-XTHBKI3-QDBKMJK-2U55FQS";
        };

        # HelloMoto — Android phone (Syncthing device name: Nintendo64)
        phone = {
          wgIp = "10.23.11.64";
          wgPublicKey = "PHONE_WG_PUBLIC_KEY"; # PLACEHOLDER — see docs/secrets.md
          syncthingId = "RNQ46P5-MED5PWA-2UAPW2O-VVA6FUK-34KPUAQ-GAEATTS-ONCPRMN-YKJ77QH";
        };
      };
    };
  };
}
