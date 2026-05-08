# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  Your digital life on your hardware, under your rules                     ║
# ║  https://github.com/markusbittermang/hallway                              ║
# ╚════════════════╝

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

  outputs =
    {
      nixpkgs,
      flake-utils,
      home-manager,
      agenix,
      ...
    }:
    let
      # ═══════════════════════════════════════════════════════════════════════
      # HALLway NixOS Modules
      # ═══════════════════════════════════════════════════════════════════════
      hallwayModules = {
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
            # Host-specific configuration
            ./hosts/2600AD/configuration.nix

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false; # Allow Home Manager to manage packages independently
              home-manager.users.bittermang = import ./hosts/2600AD/home/bittermang.nix;
              home-manager.users.guest = import ./hosts/2600AD/home/guest.nix;
            }

            # agenix for secrets management
            agenix.nixosModules.default
          ];
        };

        # ─────────────────────────────────────────────────────────────────────
        # HALLpass.space - Minimal VPS introducer (WireGuard + Syncthing infra)
        # ─────────────────────────────────────────────────────────────────────
        "HALLpass.space" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/HALLpass.space/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false;
              home-manager.users.matt = import ./hosts/HALLpass.space/home/matt.nix;
            }

            agenix.nixosModules.default
          ];
        };
      };
    }

    # ═══════════════════════════════════════════════════════════════════════
    # Development Shell (merged with flake-utils)
    # ═══════════════════════════════════════════════════════════════════════
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "hallway-dev";

          packages =
            with pkgs;
            [
              # Core tools
              git

              # Nix tooling
              nixd # Nix language server
              nixfmt # Nix formatter (RFC 166 style)

              # Secrets tooling
              age
              ssh-to-age

              # Editor support
              direnv
              nix-direnv
            ]
            ++ [
              # Official agenix CLI (ryantm/agenix)
              agenix.packages.${system}.default
            ];

          shellHook = ''
            echo "🏠 Welcome to the HALLway development shell!"
            echo ""
            echo "Available commands:"
            echo "  nix flake check      - Validate the flake"
            echo "  nix fmt              - Format Nix files"
            echo "  nix build .#nixosConfigurations.2600AD.config.system.build.toplevel"
            echo "                       - Build 2600AD system"
            echo "  agenix -e <file.age> - Edit encrypted secrets"
            echo ""
            echo "See CONTRIBUTING.md for more information."

            # Tell agenix-cli where to find the encryption rules file.
            export RULES="$PWD/secrets.nix"

            # Prefer VS Code for editor-driven tools (agenix, git commit, etc.).
            # --wait keeps the command blocked until the file is closed.
            if command -v code >/dev/null 2>&1; then
              export EDITOR="code --wait"
              export VISUAL="code --wait"
            fi
          '';
        };

        # Formatter for `nix fmt` — nixfmt-tree integrates with nix fmt's
        # no-argument invocation style; plain pkgs.nixfmt reads from stdin.
        formatter = pkgs.nixfmt-tree;
      }
    );
}
