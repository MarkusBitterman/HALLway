# ╔════════════════╗
# ║  HALLway                                                                  ║
# ║  shell.nix - Fallback dev shell (nix-shell, bypasses flake/direnv)        ║
# ║  https://github.com/markusbitterman/hallway                              ║
# ╚════════════════╝
#
# Usage:
#   nix-shell           # Enter dev shell with tools
#   nix-shell --run CMD # Run command in dev environment
#
# When to use this instead of `nix develop` / direnv:
#   - Debugging direnv or flake evaluation failures
#   - Bootstrapping a new machine before flakes are configured
#   - Any situation where the flake itself is suspect
#
# Tools provided match devShells.default in flake.nix — keep in sync.
#
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
    nixfmt # Code formatter (RFC 166 style)
    nix-tree # Visualize dependency tree
    nix-diff # Compare derivations

    # Secrets management
    sops # Encrypted secrets (YAML + age)
    age # Encryption tool
    ssh-to-age # Convert SSH public keys to age recipients
    wireguard-tools # wg genkey / genpsk — used by rotate-key

    # Documentation
    mdbook # For future documentation builds

    # Dev tools — mirrors writeShellScriptBin entries in flake.nix devShell
    (writeShellScriptBin "rotate-key" (builtins.readFile ./scripts/rotate-key))
  ];

  shellHook = ''
    # ── Environment variables ──────────────────────────────────────────────
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export ADMIN_KEY="$HOME/.ssh/id_hallpass"
    export NIX_CONFIG="experimental-features = nix-command flakes"

    if command -v code >/dev/null 2>&1; then
      export EDITOR="code --wait"
      export VISUAL="code --wait"
    fi

    # ── Welcome message ────────────────────────────────────────────────────
    host=$(hostname)
    echo "HALLway fallback shell ($host)"
    echo ""
    echo "Secrets:   sops hosts/$host/secrets.yaml"
    echo "Key mgmt:  rotate-key <secret-name> [--passphrase]"
    echo ""
  '';
}
