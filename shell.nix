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
    (writeShellScriptBin "rotate-key" ''
      name="''${1:?Usage: rotate-key <secret-name> [--passphrase]}"
      host=$(hostname)
      case "$name" in

        ssh_key_*)
          keyfile="$HOME/.ssh/$name"
          if [[ "''${2:-}" == "--passphrase" ]]; then
            ssh-keygen -t ed25519 -C "$host-$name" -f "$keyfile"
          else
            ssh-keygen -t ed25519 -C "$host-$name" -f "$keyfile" -N ""
          fi
          echo ""
          echo "Public key — register with the target service:"
          echo ""
          cat "$keyfile.pub"
          echo ""
          echo "Next steps:"
          echo "  1. Register the public key with the target service"
          echo "  2. sops hosts/$host/secrets.yaml"
          echo "       -> set '$name' to the contents of $keyfile"
          echo "  3. If new (not a rotation): also update secrets.nix and home/<user>.nix"
          echo "  4. sudo nixos-rebuild switch --flake .#$host"
          ;;

        *psk*)
          psk=$(wg genpsk)
          echo "WireGuard PSK (copy this value into BOTH peer secrets.yaml files):"
          echo ""
          echo "$psk"
          echo ""
          echo "Next steps:"
          echo "  1. sops hosts/<host-a>/secrets.yaml  -> set '$name': <value>"
          echo "  2. sops hosts/<host-b>/secrets.yaml  -> set matching PSK key: <same value>"
          echo "  3. rebuild both hosts"
          ;;

        wg_*)
          privkey=$(wg genkey)
          pubkey=$(echo "$privkey" | wg pubkey)
          echo "WireGuard private key (SECRET — goes in secrets.yaml only):"
          echo ""
          echo "$privkey"
          echo ""
          echo "WireGuard public key (not secret — goes in the peer's configuration.nix):"
          echo ""
          echo "$pubkey"
          echo ""
          echo "Next steps:"
          echo "  1. sops hosts/$host/secrets.yaml  -> set '$name': <private key>"
          echo "  2. Add public key to the peer host's configuration.nix"
          echo "  3. rebuild both hosts"
          ;;

        *)
          echo "'$name' is an externally sourced secret — obtain the new value from its source, then:"
          echo ""
          echo "  sops hosts/$host/secrets.yaml"
          echo "    -> update '$name' with the new value"
          echo ""
          echo "  sudo nixos-rebuild switch --flake .#$host"
          ;;

      esac
    '')
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
