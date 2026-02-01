# Committing to HALLway

## Quick Start

```bash
# Check what's changed
git status

# Stage all changes
git add -A

# Commit with a message
git commit -m "your message here"

# Push to GitHub
git push origin main
```

## Commit Message Format

We follow a simple semantic versioning convention:

```
<type>: <description>

<body (optional)>
```

### Types

- `feat:` — New feature or capability
- `fix:` — Bug fix
- `docs:` — Documentation changes
- `refactor:` — Code reorganization without behavior change
- `chore:` — Build, dependencies, or tooling
- `v0.x.x:` — Version bump (include in message like "v0.0.1: Description")

### Examples

```bash
# New host implementation
git commit -m "v0.0.1: 2600AD - Atari VCS 800 initial working build"

# Feature addition
git commit -m "feat: Add TPM2 auto-unlock support for LUKS partitions"

# Bug fix
git commit -m "fix: Resolve ZFS module loading issue in Stage 1 installation"

# Documentation
git commit -m "docs: Add two-stage installation guide with space optimization"
```

## Before Pushing

1. **Verify flake syntax**:
   ```bash
   nix flake show
   ```

2. **Check git status**:
   ```bash
   git status
   ```

3. **Review changes**:
   ```bash
   git diff --staged
   ```

## Pushing

```bash
# Push to main branch
git push origin main

# Or if you prefer to be explicit
git push origin HEAD:main
```

## Viewing Commits

```bash
# See commit history
git log --oneline

# See commits with diff
git log -p

# See commits for a specific file
git log -- hosts/2600AD/INSTALLATION.md
```

## After Pushing

1. Visit [github.com/MarkusBitterman/HALLway](https://github.com/MarkusBitterman/HALLway)
2. Verify your commit appears in the main branch
3. Update the [CHANGELOG.md](CHANGELOG.md) locally for next version notes

---

## Syncing with Remote

```bash
# Fetch latest from GitHub
git fetch origin

# Pull changes (fetch + merge)
git pull origin main

# See what's different
git log HEAD..origin/main
```

## Troubleshooting

### "Permission denied (publickey)"
You're using IDE authentication, not SSH keys. This is fine! The IDE handles it for you when you push.

### "Everything up-to-date"
All your commits are already pushed. Run `git log` to see history.

### "Dirty working tree"
You have uncommitted changes. Use `git status` to see what, then:
```bash
git add -A
git commit -m "your message"
```

---

**Ready?** Run:
```bash
cd ~/nix/hallway
git status
```
