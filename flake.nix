{
  description = "HALLway OS - Your digital life on your hardware, under your rules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
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
            echo "  nix flake check  - Validate the flake"
            echo "  nix fmt          - Format Nix files"
            echo ""
            echo "See CONTRIBUTING.md for more information."
          '';
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
