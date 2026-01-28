# Development Tools 🛠️

This document describes the development tools and workflows used in HALLway.

## Nix Development Environment

HALLway uses Nix flakes for reproducible development environments.

### Why Nix?

> Nix gives us the boring superpower that makes everything else possible:
> - **Reproducible builds** (no "works on my machine" ghost stories) 👻
> - **Declarative configs** (systems are described, not accidentally assembled) 🧾
> - Easy to audit "what changed" between builds 🔎
>
> — HALLway Project Bible

### Tools in the Dev Shell

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `nixd` | Nix language server for editor integration |
| `nixfmt` | Nix code formatter (nixfmt-rfc-style, RFC 166 style) |
| `direnv` | Automatic environment activation |
| `nix-direnv` | Fast direnv integration for Nix |

### Common Commands

```bash
# Enter the development shell
nix develop

# Validate the flake
nix flake check

# Format Nix files
nix fmt

# Update flake inputs
nix flake update
```

## Editor Setup

### VS Code

Recommended extensions are listed in [.vscode/extensions.json](../.vscode/extensions.json):

- **Nix IDE** (`jnoortheen.nix-ide`) - Nix language support
- **EditorConfig** (`editorconfig.editorconfig`) - Consistent formatting
- **GitHub Copilot** (`github.copilot`) - AI assistance
- **GitHub Copilot Chat** (`github.copilot-chat`) - AI chat interface
- **direnv** (`mkhl.direnv`) - Automatic dev shell activation

### Other Editors

Any editor that supports:
- EditorConfig (for consistent formatting)
- LSP (for Nix language server integration)

Should work well with this project.

## AI-Assisted Development

### GitHub Copilot

We use Copilot as a **power tool, not an authority**:

- ✅ Use for drafting, exploration, and acceleration
- ✅ Always review and test suggestions
- 🚫 Never include secrets or credentials in prompts
- 🚫 Don't blindly accept suggestions

See [CONTRIBUTING.md](../CONTRIBUTING.md#working-with-copilot) for detailed guidelines.

### MCP (Model Context Protocol)

If you're using MCP-compatible tools:

1. **Context matters** - Provide relevant context to your AI tools
2. **Verify outputs** - All AI-generated code must be human-reviewed
3. **Security first** - Never expose secrets through AI tooling
4. **Document learnings** - If an AI tool helps you discover something useful, consider documenting it

## Continuous Integration

*(Coming soon)*

Future CI will include:
- Nix flake checks
- Formatting verification
- Security scanning

## Code Quality

### Formatting

All code is automatically formatted:
- **Nix**: `nixfmt` (nixfmt-rfc-style, RFC 166 style)
- **General**: EditorConfig settings

Run `nix fmt` before committing.

### Linting

*(Linters will be added as the codebase grows)*

## Troubleshooting

### "Nix command not found"

Make sure Nix is installed and flakes are enabled:

```bash
# Check Nix installation
nix --version

# Enable flakes (add to ~/.config/nix/nix.conf)
# Check if flakes are already enabled
grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null || \
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "Flake check fails"

```bash
# Update flake inputs
nix flake update

# Try again
nix flake check
```

### "nixd not working in VS Code"

1. Make sure you're in the dev shell (`nix develop`)
2. Restart VS Code
3. Check that Nix IDE extension is installed

---

For more help, see [CONTRIBUTING.md](../CONTRIBUTING.md) or open an issue.
