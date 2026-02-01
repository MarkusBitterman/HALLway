# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  HALLway                                                                  ║
# ║  shell.nix - Development Shell (alternative to `nix develop`)            ║
# ║  https://github.com/markusbitterman/hallway                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   nix-shell           # Enter dev shell with tools
#   nix-shell --run CMD # Run command in dev environment
#
# Tools provided:
#   - git, gh (GitHub CLI)
#   - nixd (Nix LSP), nixfmt (formatter)
#   - agenix (secrets management)
#
# For installation/deployment:
#   - git, gh for cloning and pushing
#   - nixos-install reads this repo's flake.nix
# ═══════════════════════════════════════════════════════════════════════════════

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "hallway-dev";

  buildInputs = with pkgs; [
    # Version control
    git
    gh                      # GitHub CLI (for cloning, PRs, issues)

    # Nix development
    nixd                    # Nix LSP server
    nixfmt-rfc-style        # Code formatter
    nix-tree                # Visualize dependency tree
    nix-diff                # Compare derivations

    # Secrets management
    age                     # Encryption tool
    # agenix requires flake inputs, not available in shell.nix

    # Documentation
    mdbook                  # For future documentation builds
  ];

  shellHook = ''
    echo "🌍 HALLway Development Environment"
    echo ""
    echo "Available commands:"
    echo "  nix flake check         - Validate flake"
    echo "  nix fmt                 - Format .nix files"
    echo "  nix build .#2600AD...   - Build system configuration"
    echo "  git / gh                - Version control"
    echo "  agenix -e <file>        - Edit encrypted secrets"
    echo ""
    echo "For installation, see INSTALLATION.md"
    echo "For contributing, see CONTRIBUTING.md"
    echo ""

    # Enable experimental features for this shell session
    export NIX_CONFIG="experimental-features = nix-command flakes"
  '';
}
