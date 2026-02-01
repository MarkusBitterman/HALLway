# HALLway Troubleshooting Guide 🔧

This guide consolidates all known issues and solutions across HALLway installations.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Boot & LUKS Issues](#boot--luks-issues)
- [ZFS Issues](#zfs-issues)
- [Development Environment Issues](#development-environment-issues)
- [Package & Build Issues](#package--build-issues)
- [Home Manager Issues](#home-manager-issues)

---

## Installation Issues

### "No space left on device" during install

**Cause**: The NixOS installer uses a ~3GB RAM-based tmpfs for `/nix/.rw-store`, which fills up quickly.

**Solutions**:
1. **Use `nixos-install` directly** - it builds to the target store, not tmpfs (recommended)
2. **Run garbage collection**: `sudo nix-collect-garbage -d`
3. **Add swap** from a spare USB drive for overflow:
   ```bash
   sudo mkswap /dev/sdX1
   sudo swapon /dev/sdX1
   ```
4. **Avoid running `nix build`** - use `nix flake check` for validation instead (minimal disk usage)

**References**: 
- [Generic Installation Guide - Troubleshooting](../INSTALLATION.md#troubleshooting)
- [2600AD Installation Guide - Step 6](../hosts/2600AD/INSTALLATION.md#step-6-install-nixos)

---

### "experimental feature 'flakes' is disabled"

**Cause**: The installer may not have flakes enabled by default.

**Solutions**:
1. **Use nix-shell**: 
   ```bash
   cd /mnt/<hostname>/etc/nixos
   nix-shell  # Enters shell with flakes enabled
   nix flake check
   ```
2. **Set environment variable**:
   ```bash
   export NIX_CONFIG="experimental-features = nix-command flakes"
   ```

**Reference**: [Generic Installation Guide](../INSTALLATION.md#troubleshooting)

---

## Boot & LUKS Issues

### ZFS pool fails to import during boot

**Symptoms**: Boot hangs or drops to emergency shell, ZFS pool not found.

**Solution**:
1. Boot from USB installer
2. Decrypt the LUKS container:
   ```bash
   # For 2600AD (adjust labels for your host)
   sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt
   ```
3. Import the pool manually:
   ```bash
   sudo zpool import -f <poolname>
   ```
4. Check pool status:
   ```bash
   sudo zpool status
   ```
5. Mount and `nixos-enter` to fix configuration

**References**:
- [2600AD Troubleshooting](../hosts/2600AD/INSTALLATION.md#zfs-pool-already-imported)
- [2600AD README Troubleshooting](../hosts/2600AD/README.md#if-zfs-import-fails-during-boot)

---

### TPM2 auto-unlock fails

**Symptoms**: Boot prompts for LUKS passphrase despite TPM2 enrollment.

**Solution**:
1. Boot with passphrase
2. Re-enroll TPM2 (for 2600AD, adjust labels for your host):
   ```bash
   # For SSD/root
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-label/CARTRIDGE
   
   # For swap
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-label/STELLA
   ```
3. Verify enrollment:
   ```bash
   sudo systemd-cryptenroll /dev/disk/by-label/CARTRIDGE
   ```
4. Make sure `hardware-configuration.nix` has TPM2 options:
   ```nix
   boot.initrd.luks.devices."<name>".crypttabExtraOpts = [ "tpm2-device=auto" ];
   ```

**References**:
- [2600AD Installation Guide - TPM2 Enrollment](../hosts/2600AD/INSTALLATION.md#post-install-tpm2-auto-unlock-optional)
- [2600AD README Troubleshooting](../hosts/2600AD/README.md#if-tpm2-unlock-fails)

---

### "LUKS device already open"

**Symptoms**: Error when trying to open LUKS container during installation.

**Solution**:
```bash
# Close existing mapping (adjust names for your host)
sudo cryptsetup close cartridge_crypt
sudo cryptsetup close stella

# Then retry opening
sudo cryptsetup open /dev/disk/by-label/CARTRIDGE cartridge_crypt
```

**Reference**: [2600AD Installation Guide](../hosts/2600AD/INSTALLATION.md#luks-device-already-open)

---

## ZFS Issues

### "ZFS pool already imported"

**Symptoms**: Error when trying to import ZFS pool during installation.

**Solution**:
```bash
sudo zpool export <poolname>
# Then retry import
sudo zpool import <poolname>
```

**Reference**: [2600AD Installation Guide](../hosts/2600AD/INSTALLATION.md#zfs-pool-already-imported)

---

### "Mount point busy"

**Symptoms**: Cannot unmount ZFS filesystems during cleanup.

**Solution**:
```bash
# Unmount recursively
sudo umount -R /mnt/<hostname>

# If still busy, kill processes using the mount
sudo fuser -km /mnt/<hostname>
```

**Reference**: [2600AD Installation Guide](../hosts/2600AD/INSTALLATION.md#mount-point-busy)

---

### Hibernation doesn't work

**Symptoms**: `systemctl hibernate` fails or system doesn't resume properly.

**Solution**:
1. Verify swap is active:
   ```bash
   swapon --show
   ```
2. Check resume device in `configuration.nix` matches your swap mapper:
   ```nix
   boot.resumeDevice = "/dev/mapper/<swap-mapper-name>";
   ```
3. For 2600AD, it should be `/dev/mapper/stella`
4. Test hibernation:
   ```bash
   systemctl hibernate
   ```

**References**:
- [2600AD README Troubleshooting](../hosts/2600AD/README.md#if-hibernation-doesnt-work)

---

## Development Environment Issues

### "Nix command not found"

**Cause**: Nix is not installed or not in PATH.

**Solution**:
1. Check Nix installation:
   ```bash
   nix --version
   ```
2. Enable flakes (add to `~/.config/nix/nix.conf`):
   ```
   experimental-features = nix-command flakes
   ```
3. Or check automatically:
   ```bash
   grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null || \
     echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

**Reference**: [Dev Tools Guide](dev-tools.md#nix-command-not-found)

---

### "Flake check fails"

**Symptoms**: `nix flake check` reports errors.

**Solution**:
1. Update flake inputs:
   ```bash
   nix flake update
   ```
2. Try again:
   ```bash
   nix flake check
   ```
3. If errors persist, check the specific error message for syntax or module issues

**Reference**: [Dev Tools Guide](dev-tools.md#flake-check-fails)

---

### "nixd not working in VS Code"

**Symptoms**: Nix language server not providing completions or diagnostics.

**Solution**:
1. Make sure you're in the dev shell:
   ```bash
   nix develop
   ```
2. Restart VS Code
3. Check that Nix IDE extension is installed
4. Verify `nixd` is available:
   ```bash
   which nixd
   ```

**Reference**: [Dev Tools Guide](dev-tools.md#nixd-not-working-in-vs-code)

---

## Package & Build Issues

### Package rename errors (rofi-wayland, onlyoffice-bin, etc.)

**Symptoms**: Build fails with "attribute ... missing" for packages.

**Common Renames** (as of 2026-01):
- `rofi-wayland` → `rofi`
- `onlyoffice-bin` → `onlyoffice-desktopeditors`
- `musicbrainz-picard` → `picard`

**Solution**: Check [CHANGELOG.md](../CHANGELOG.md#fixed) for package renames and update your configuration.

**Reference**: [2600AD Installation Guide](../hosts/2600AD/INSTALLATION.md#package-renamesremovals)

---

### ZFS kernel compatibility issues

**Symptoms**: "broken package: zfs-kernel" or similar errors during build.

**Cause**: ZFS kernel modules must match the kernel version exactly.

**Solution**: 
1. Use stable kernel instead of zen/latest:
   ```nix
   boot.kernelPackages = pkgs.linuxPackages;  # Instead of linuxPackages_zen
   ```
2. Or wait for ZFS to support your kernel version

**Reference**: [CHANGELOG.md](../CHANGELOG.md#changed)

---

### "amdvlk driver not found"

**Symptoms**: Build fails looking for `amdvlk` package.

**Cause**: `amdvlk` was removed from nixpkgs; RADV is now the default AMD driver.

**Solution**: Remove `amdvlk` from your `hardware.opengl.extraPackages`:
```nix
# OLD (don't use)
hardware.opengl.extraPackages = with pkgs; [ amdvlk ];

# NEW (use RADV - already default)
hardware.opengl.enable = true;
```

**Reference**: [CHANGELOG.md](../CHANGELOG.md#fixed)

---

## Home Manager Issues

### XDG Portal errors

**Symptoms**: Home Manager errors about missing XDG portal paths.

**Solution**: Add to your `configuration.nix`:
```nix
environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
```

**Reference**: 
- [CHANGELOG.md](../CHANGELOG.md#fixed)
- [2600AD Installation Guide](../hosts/2600AD/INSTALLATION.md#home-manager-xdg-portal-error)

---

### VSCode package conflict

**Symptoms**: "buildEnv collision" between system and Home Manager VSCode installations.

**Solution**: Install VSCode at system level (via role groups), configure via Home Manager:
```nix
# In configuration.nix (or via roles.users.<name>.groups)
users.users.<name>.packages = with pkgs; [ vscode ];

# In home/<name>.nix (configure only, don't install)
programs.vscode = {
  enable = true;
  # ... configuration only
};
```

**Reference**: [CHANGELOG.md](../CHANGELOG.md#fixed)

---

## Getting More Help

If your issue isn't listed here:

1. **Check the documentation**:
   - [README.md](../README.md) - Overview and user management
   - [INSTALLATION.md](../INSTALLATION.md) - Generic installation guide
   - [CONTRIBUTING.md](../CONTRIBUTING.md) - Development setup
   - [CHANGELOG.md](../CHANGELOG.md) - Recent fixes and changes

2. **Check host-specific guides**:
   - [2600AD Installation](../hosts/2600AD/INSTALLATION.md)
   - [2600AD README](../hosts/2600AD/README.md)

3. **Search the repository**: Use GitHub's search or `grep` to find similar issues

4. **Open an issue**: [GitHub Issues](https://github.com/MarkusBitterman/HALLway/issues)

---

**Last Updated**: 2026-02-01
