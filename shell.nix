# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  shell.nix - Development Shell (alternative to `nix develop`)            ║
# ║  https://github.com/markusbitterman/hallway                              ║
# ╚════════════════╝
#
# Usage:
#   nix-shell           # Enter dev shell with tools
#   nix-shell --run CMD # Run command in dev environment
#
# Tools provided:
#   - git, gh (GitHub CLI)
#   - nixd (Nix LSP), nixfmt (formatter)
#   - age, ssh-to-age (secrets management)
#   - agenix command wrapper (official ryantm/agenix)
#
# For installation/deployment:
#   - git, gh for cloning and pushing
#   - nixos-install reads this repo's flake.nix
# ════════════════════

{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "hallway-dev";

  buildInputs = with pkgs; [
    # Version control
    git
    gh # GitHub CLI (for cloning, PRs, issues)

    # Nix development
    nixd # Nix LSP server
    nixfmt # Code formatter
    nix-tree # Visualize dependency tree
    nix-diff # Compare derivations

    # Secrets management
    age # Encryption tool
    ssh-to-age # Convert SSH public keys to age recipients

    # Documentation
    mdbook # For future documentation builds
  ];

  shellHook = ''
    echo "🌍 HALLway Development Environment"
    echo ""
    echo "Available commands:"
    echo "  nix flake check         - Validate flake"
    echo "  nix fmt                 - Format .nix files"
    echo "  nix build .#2600AD...   - Build system configuration"
    echo "  git / gh                - Version control"
    echo "  agenix -e <file.age>    - Edit encrypted secrets"
    echo "  ssh-to-age < key.pub    - Convert SSH pubkey to age recipient"
    echo ""
    echo "For installation, see INSTALLATION.md"
    echo "For contributing, see CONTRIBUTING.md"
    echo ""

    # Enable experimental features for this shell session
    export NIX_CONFIG="experimental-features = nix-command flakes"

    # Tell agenix-cli where to find the encryption rules file.
    # This means `agenix -e hosts/<host>/secrets/<name>.age` Just Works
    # without needing to specify -r or set RULES manually.
    export RULES="$PWD/secrets.nix"

    # Prefer VS Code for editor-driven tools (agenix, git commit, etc.).
    # --wait keeps the command blocked until the file is closed.
    if command -v code >/dev/null 2>&1; then
      export EDITOR="code --wait"
      export VISUAL="code --wait"
    fi

    # Use official agenix implementation (ryantm/agenix).
    # This avoids the incompatible `agenix-cli` behavior on nix-shell.
    agenix() {
      nix run github:ryantm/agenix -- "$@"
    }
  '';
}
