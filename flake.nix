# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway                                                                  ║
# ║  Your digital life on your hardware, under your rules                     ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

{
  description = "HALLway OS - Your digital life on your hardware, under your rules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Home Manager (for user environment configuration)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # agenix for secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, agenix, ... }:
    let
      # ═══════════════════════════════════════════════════════════════════════
      # HALLway NixOS Modules
      # ═══════════════════════════════════════════════════════════════════════
      hallwayModules = {
        roles = ./modules/userRoles.nix;
        default = ./modules/default.nix;
      };
      
    in
    {
      # ═══════════════════════════════════════════════════════════════════════
      # Export HALLway as NixOS modules for other flakes
      # ═══════════════════════════════════════════════════════════════════════
      nixosModules = hallwayModules;

      # ═══════════════════════════════════════════════════════════════════════
      # Machine Configurations (HALLway Hosts)
      # ═══════════════════════════════════════════════════════════════════════
      nixosConfigurations = {
        
        # ─────────────────────────────────────────────────────────────────────
        # 2600AD - Atari VCS 800 Gaming/Media Workstation
        # First HALLway implementation (v0.0.1)
        # ─────────────────────────────────────────────────────────────────────
        "2600AD" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # HALLway modules
            hallwayModules.roles
            
            # Host-specific configuration
            ./hosts/2600AD/configuration.nix
            
            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bittermang = import ./hosts/2600AD/home/bittermang.nix;
            }
            
            # agenix for secrets
            agenix.nixosModules.default
            ./hosts/2600AD/secrets.nix
          ];
        };
      };
    }
    
    # ═══════════════════════════════════════════════════════════════════════
    # Development Shell (merged with flake-utils)
    # ═══════════════════════════════════════════════════════════════════════
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "hallway-dev";

          packages = with pkgs; [
            # Core tools
            git

            # Nix tooling
            nixd              # Nix language server
            nixfmt-rfc-style  # Nix formatter (RFC 166 style)

            # Editor support
            direnv
            nix-direnv
          ];

          shellHook = ''
            echo "🏠 Welcome to the HALLway development shell!"
            echo ""
            echo "Available commands:"
            echo "  nix flake check      - Validate the flake"
            echo "  nix fmt              - Format Nix files"
            echo "  nix build .#nixosConfigurations.2600AD.config.system.build.toplevel"
            echo "                       - Build 2600AD system"
            echo ""
            echo "See CONTRIBUTING.md for more information."
          '';
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
