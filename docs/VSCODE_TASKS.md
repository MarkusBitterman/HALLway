# VS Code Tasks for HALLway 🛠️

HALLway includes pre-configured VS Code tasks to streamline installation and development workflows. These tasks are defined in [`.vscode/tasks.json`](../.vscode/tasks.json).

## Quick Access

- **Run any task**: Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) → Type "Tasks: Run Task"
- **Run default build**: Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on macOS)
- **Run default test**: Press `Ctrl+Shift+P` → "Tasks: Run Test Task"

---

## Task Categories

### 🧪 Validation Tasks

Pre-install checks with minimal disk usage. Safe to run in the installer's limited tmpfs environment.

#### ✅ Verify (Default Test Task)
- **Shortcut**: `Ctrl+Shift+P` → "Tasks: Run Test Task"
- **What it does**: Validates flake syntax and evaluates modules
- **Use when**: Before installation to catch syntax errors
- **Disk usage**: Minimal (~100MB)
- **Output**: Logged to `logs/validation-<timestamp>.log`

**Example**:
```
Tasks: Run Test Task
```

---

#### 🧑‍🔬 Test All
- **What it does**: Comprehensive validation - flake check + system eval + Home Manager eval
- **Use when**: Thorough pre-install validation
- **Disk usage**: Low (~200-300MB)
- **Output**: Logged to `logs/validation-<timestamp>.log`

---

### 🚀 Installation Tasks

Build and install to target ZFS store (bypasses tmpfs limitations).

#### 🚀 Install (Default Build Task)
- **Shortcut**: `Ctrl+Shift+B` (or `Cmd+Shift+B`)
- **What it does**: Full NixOS installation to `/mnt/2600AD`
- **Target**: Builds directly to ZFS store (903GB free)
- **Use when**: Ready to install after validation passes
- **Output**: Logged to `logs/install-<timestamp>.log`, symlinked to `install-history.log`

**Command equivalent**:
```bash
sudo nixos-install --root /mnt/2600AD --flake .#2600AD --no-root-passwd
```

---

#### 🛠️ Build ZFS
- **What it does**: Builds system configuration to target ZFS store without installing
- **Use when**: Testing build without installation
- **Output**: Logged to `logs/build-<timestamp>.log`

---

### 🔧 Daily Development Tasks

Formatting and cleanup utilities.

#### ✨ Format
- **What it does**: Formats all Nix files using `nixfmt-rfc-style` (RFC 166)
- **Use when**: Before committing changes
- **Shortcut**: Run task → "✨ Format"

**Command equivalent**:
```bash
nix fmt
```

---

#### 🗑️ Clean
- **What it does**: Removes build results and log files
- **Cleans**:
  - `result`, `result-*` symlinks
  - `logs/` directory
- **Use when**: Cleaning up workspace

---

### 🔄 Flake & Rebuild Tasks

Update dependencies and apply configuration changes.

#### 🔄 Update All
- **What it does**: Updates all flake inputs (nixpkgs, home-manager, agenix)
- **Use when**: Updating to latest package versions
- **Output**: Updates `flake.lock`

**Command equivalent**:
```bash
nix flake update
```

---

#### ⚡ Switch
- **What it does**: Rebuilds and activates new configuration (post-install only)
- **Use when**: After modifying `configuration.nix` or other config files
- **Requires**: Running system (not from installer)

**Command equivalent**:
```bash
sudo nixos-rebuild switch --flake .#2600AD
```

---

### 🗑️ Maintenance Tasks

Disk space management for installer environment.

#### 🖴 Disk Space
- **What it does**: Shows disk space for tmpfs, ZFS target, swap, and memory
- **Use when**: Checking available space before builds
- **Shows**:
  - `/nix/.rw-store` (installer tmpfs - limited to ~3GB)
  - `/mnt/2600AD` (ZFS target)
  - Swap status
  - Memory usage

---

#### 🔥🗑️ GC Now
- **What it does**: Garbage collects Nix store to free space
- **Use when**: Running low on tmpfs space in installer
- **Frees**: Unused Nix store paths
- **Shows**: Disk space after cleanup

**Command equivalent**:
```bash
sudo nix-collect-garbage -d
```

---

## Typical Installation Workflow

### During Installation (from USB installer)

1. **✅ Verify** - Validate flake before starting
2. **🖴 Disk Space** - Check available space
3. **🚀 Install** - Perform installation (builds to ZFS, not tmpfs)
4. Monitor logs in `logs/install-<timestamp>.log`

If space issues occur:
- Run **🔥🗑️ GC Now** to free tmpfs space
- Verify you're using **🚀 Install** (not `nix build`) to build to ZFS

---

### After Installation (on running system)

1. Make config changes in `/etc/nixos`
2. **✨ Format** - Format modified Nix files
3. **✅ Verify** - Validate changes
4. **⚡ Switch** - Apply new configuration
5. **🔄 Update All** - Periodically update dependencies

---

## Log Files

All tasks with significant output save logs to `logs/`:

| Log File | Task | Description |
|----------|------|-------------|
| `validation-<timestamp>.log` | ✅ Verify, 🧑‍🔬 Test All | Validation output |
| `install-<timestamp>.log` | 🚀 Install | Installation output |
| `build-<timestamp>.log` | 🛠️ Build ZFS | Build output |
| `install-history.log` | 🚀 Install | Symlink to latest install log |
| `validation.log` | ✅ Verify | Symlink to latest validation log |

Logs are automatically timestamped and preserved for debugging.

---

## Troubleshooting Tasks

### Task fails with "nix: command not found"

You're not in the Nix environment. Tasks automatically use `nix-shell --run` to ensure Nix is available.

**Solution**: Make sure you're running from the repository root where `shell.nix` exists.

---

### "No space left on device" during Install

The installer's tmpfs is full (~3GB limit).

**Solution**: 
1. Run **🔥🗑️ GC Now** to free space
2. Use **🚀 Install** task (builds to ZFS target, not tmpfs)
3. Avoid running `nix build` - use **✅ Verify** instead

See [Troubleshooting Guide](TROUBLESHOOTING.md#no-space-left-on-device-during-install) for details.

---

### Task output not visible

**Solution**: Tasks are configured to show output in VS Code's integrated terminal. Check the "Terminal" panel (View → Terminal).

---

## Customizing Tasks

To modify tasks for your environment:

1. Open `.vscode/tasks.json`
2. Edit task properties:
   - `command` - Shell command to run
   - `detail` - Task description
   - `problemMatcher` - Error detection (currently disabled)
3. Change host name if not using `2600AD`:
   ```json
   "command": "... --flake .#<your-hostname>"
   ```

---

## Related Documentation

- [Development Tools](dev-tools.md) - Overview of Nix development environment
- [Contributing Guide](../CONTRIBUTING.md) - Development workflow
- [Installation Guide](../hosts/2600AD/INSTALLATION.md) - Step-by-step installation
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions

---

**Last Updated**: 2026-02-01
