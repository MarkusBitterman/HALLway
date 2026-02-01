# HALLway NixOS Modules
#
# This directory contains reusable NixOS modules that implement HALLway concepts.
#
# Available modules:
#   - userRoles.nix : Role-based user management with package groups

{ ... }:

{
  imports = [
    ./userRoles.nix
  ];
}
