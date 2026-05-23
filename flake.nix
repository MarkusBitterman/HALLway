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

    # sops-nix for secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DOORwayDE - Hyprland desktop environment (HyDE port)
    doorwayde = {
      url = "github:MarkusBitterman/DOORwayDE";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      sops-nix,
      doorwayde,
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
      # Standalone Home Manager configurations (non-NixOS hosts)
      # ═══════════════════════════════════════════════════════════════════════
      homeConfigurations = {

        # ─────────────────────────────────────────────────────────────────────
        # HelloMoto - Android phone (Termux + Nix, aarch64-linux)
        # Activate with: home-manager switch --flake .#HelloMoto
        # ─────────────────────────────────────────────────────────────────────
        "HelloMoto" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-linux";
          modules = [
            ./hosts/HelloMoto/home/user.nix
            sops-nix.homeManagerModules.sops
          ];
        };
      };

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
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.backupFileExtension = "backup";
              home-manager.users.bittermang = import ./hosts/2600AD/home/bittermang.nix;
              home-manager.users.guest = import ./hosts/2600AD/home/guest.nix;
            }

            # sops-nix for secrets management
            sops-nix.nixosModules.sops
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

            sops-nix.nixosModules.sops
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

          packages = with pkgs; [
            # Core tools
            git

            # Nix tooling
            nixd # Nix language server
            nixfmt # Nix formatter (RFC 166 style)

            # Secrets tooling (sops + age backend)
            sops
            age
            ssh-to-age
            wireguard-tools

            # Editor support
            direnv
            nix-direnv
          ];

          shellHook = ''
            # ── Environment variables ─────────────────────────────────────────
            export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
            export ADMIN_KEY="$HOME/.ssh/id_hallpass"

            # Prefer VS Code for editor-driven tools (sops, git commit, etc.).
            if command -v code >/dev/null 2>&1; then
              export EDITOR="code --wait"
              export VISUAL="code --wait"
            fi

            # ── Host detection ────────────────────────────────────────────────
            HALLWAY_HOST=$(hostname)

            # ── Aliases ───────────────────────────────────────────────────────
            alias check='nix flake check'
            alias fmt='nix fmt'
            alias rebuild="sudo nixos-rebuild switch --flake .#$HALLWAY_HOST"
            alias build="nix build .#nixosConfigurations.$HALLWAY_HOST.config.system.build.toplevel"

            # ── Functions ─────────────────────────────────────────────────────
            # Generate an SSH key and print guided next steps.
            # Usage: rotate-key <secret-name> [--passphrase]
            #   <secret-name>  sops key name; key is written to ~/.ssh/<secret-name>
            #   --passphrase   prompt for a passphrase (default: none, automation-safe)
            rotate-key() {
              local name="''${1:?Usage: rotate-key <secret-name> [--passphrase]}"
              local keyfile="$HOME/.ssh/$name"
              if [[ "''${2:-}" == "--passphrase" ]]; then
                ssh-keygen -t ed25519 -C "$HALLWAY_HOST-$name" -f "$keyfile"
              else
                ssh-keygen -t ed25519 -C "$HALLWAY_HOST-$name" -f "$keyfile" -N ""
              fi
              echo ""
              echo "Public key — register with the target service:"
              echo ""
              cat "$keyfile.pub"
              echo ""
              echo "Next steps:"
              echo "  1. Register the public key with the target service"
              echo "  2. sops hosts/$HALLWAY_HOST/secrets.yaml"
              echo "       → set '$name' to the contents of $keyfile"
              echo "  3. If new (not a rotation): also update secrets.nix and home/<user>.nix"
              echo "  4. rebuild"
            }

            # ── Welcome message ───────────────────────────────────────────────
            echo "HALLway dev shell ($HALLWAY_HOST)"
            echo ""

            # Git status
            if git rev-parse --git-dir > /dev/null 2>&1; then
              branch=$(git branch --show-current)
              if git diff --quiet 2>/dev/null; then
                echo "Branch: $branch"
              else
                echo "Branch: $branch (dirty)"
              fi
            fi

            # SOPS key status
            if [[ -f "$SOPS_AGE_KEY_FILE" ]]; then
              echo "SOPS age key: $SOPS_AGE_KEY_FILE"
            else
              echo "SOPS age key missing! Run:"
              echo "   mkdir -p ~/.config/sops/age"
              echo "   age-keygen -o ~/.config/sops/age/keys.txt"
            fi

            echo ""
            echo "Aliases:   check, fmt, build, rebuild"
            echo "Secrets:   sops hosts/$HALLWAY_HOST/secrets.yaml"
            echo "Key mgmt:  rotate-key <secret-name> [--passphrase]"
            echo ""
          '';
        };

        # Formatter for `nix fmt` — nixfmt-tree integrates with nix fmt's
        # no-argument invocation style; plain pkgs.nixfmt reads from stdin.
        formatter = pkgs.nixfmt-tree;
      }
    );
}
