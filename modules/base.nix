# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/base.nix - Shared baseline for every HALLway NixOS host          ║
# ╚════════════════╝
#
# Settings every HALLway host starts from. Everything host-overridable is set
# with lib.mkDefault so a host config wins with a plain assignment — no
# mkForce ceremony required.

{ lib, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════
  # Boot
  # ═══════════════════════════════════════════════════════════════════════

  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  zramSwap.enable = lib.mkDefault true;

  # ═══════════════════════════════════════════════════════════════════════
  # Nix
  # ═══════════════════════════════════════════════════════════════════════

  nix.settings = {
    auto-optimise-store = lib.mkDefault true;
    # Flake-based hosts always need these; list values from hosts merge in.
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════
  # Localization
  # ═══════════════════════════════════════════════════════════════════════

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # ═══════════════════════════════════════════════════════════════════════
  # Baseline security
  # ═══════════════════════════════════════════════════════════════════════

  security.apparmor.enable = lib.mkDefault true;
  networking.firewall.enable = lib.mkDefault true;

  # ═══════════════════════════════════════════════════════════════════════
  # Services & programs
  # ═══════════════════════════════════════════════════════════════════════

  services.openssh.enable = lib.mkDefault true;
  programs.zsh.enable = lib.mkDefault true;
}
