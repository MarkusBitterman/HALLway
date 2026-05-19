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
#   - sops, age, ssh-to-age (secrets management)
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
    sops # Encrypted secrets (YAML + age)
    age # Encryption tool
    ssh-to-age # Convert SSH public keys to age recipients

    # Documentation
    mdbook # For future documentation builds
  ];

  shellHook = ''
    echo "🌍 HALLway Development Environment"
    echo ""
    echo "Available commands:"
    echo "  nix flake check            - Validate flake"
    echo "  nix fmt                    - Format .nix files"
    echo "  nix build .#2600AD...      - Build system configuration"
    echo "  git / gh                   - Version control"
    echo "  sops hosts/<host>/secrets.yaml - Edit encrypted secrets"
    echo "  ssh-to-age < key.pub       - Convert SSH pubkey to age recipient"
    echo ""
    echo "For installation, see README.md"
    echo "For contributing, see CONTRIBUTING.md"
    echo ""

    # Enable experimental features for this shell session
    export NIX_CONFIG="experimental-features = nix-command flakes"

    # Tell sops where to find the age key
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

    # Prefer VS Code for editor-driven tools (sops, git commit, etc.).
    # --wait keeps the command blocked until the file is closed.
    if command -v code >/dev/null 2>&1; then
      export EDITOR="code --wait"
      export VISUAL="code --wait"
    fi
  '';
}
