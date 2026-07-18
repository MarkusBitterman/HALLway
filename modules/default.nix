# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  modules/default.nix - HALLway shared module aggregator                   ║
# ╚════════════════╝
#
# Imported by every HALLway NixOS host (via flake.nix) and exported as
# nixosModules.default for other flakes.
#
# Available modules:
#   - base.nix  — shared baseline defaults (boot, nix, security, services)
#   - mesh.nix  — hallway.mesh registry: WireGuard + Syncthing public identifiers

{ ... }:

{
  imports = [
    ./base.nix
    ./mesh.nix
  ];
}
