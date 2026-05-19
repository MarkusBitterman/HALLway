# TODO

## HALLpass.space — First Deployment

HALLpass.space configuration exists but has never been deployed. Placeholder values must be replaced and sops must be rekeyed before it can activate.

- [ ] DNS first: point `hallpass.space`, `hg.hallpass.space` A records at VPS IP (ACME HTTP-01 requires this before first deploy)
- [ ] Provision VPS and run `nixos-install --flake .#HALLpass.space`
- [ ] Get VPS SSH host key and add to `.sops.yaml` as `hallpass` recipient:
  ```bash
  ssh-keyscan hallpass.space | grep ed25519 | ssh-to-age
  # Add to .sops.yaml under keys, uncomment in creation_rules, then:
  sops updatekeys hosts/HALLpass.space/secrets.yaml
  ```
- [ ] Generate WireGuard keypairs (see `docs/secrets.md`) and replace placeholders:
  - `894D+6bHWTBC3CXPbtn9Nv/hTnk+vOnd0PrshTPMxQo=` in `hosts/2600AD/configuration.nix`
  - `DESKTOP_WG_PUBLIC_KEY` in `hosts/HALLpass.space/configuration.nix`
  - `PHONE_WG_PUBLIC_KEY` in `hosts/HALLpass.space/configuration.nix`
- [ ] After first Syncthing startup on HALLpass.space, replace:
  - `HALLPASS_SYNCTHING_DEVICE_ID` in `hosts/2600AD/configuration.nix`
  - `DISCOVERY_SERVER_ID` (from `journalctl -u syncthing-discovery`)
  - `RELAY_SERVER_ID` (from `journalctl -u syncthing.service`)
- [ ] After phone WireGuard/Syncthing setup: replace `PHONE_SYNCTHING_DEVICE_ID`
- [ ] Initialize HALLway repo on server: `ssh matt@hallpass.space "hg init /srv/hg/repos/hallway"`
- [ ] Place an `index.html` at `/srv/hallspace/_public/index.html`

## HALLpass.space — Web + Mercurial

- [x] nginx virtual hosts: `hallpass.space` (static `/srv/hallspace/_public/`) and `hg.hallpass.space` (Mercurial proxy to loopback hgweb)
- [x] ACME/TLS via Let's Encrypt (`enableACME + forceSSL` on both vhosts)
- [x] hgweb systemd service (port 8085, repos at `/srv/hg/repos/**`)
- [x] `age` and `ssh-to-age` in system packages for on-server key operations
- [ ] Migrate this repo from Git to Mercurial: `hg convert` or `git-hg`, push to `hg.hallpass.space`
- [ ] Configure GitHub as a read-only mirror of the Hg repo
- [ ] Update CLAUDE.md, CONTRIBUTING.md, and README.md to reflect Hg as primary VCS

## 2600AD — HALLwayDE Integration

HALLwayDE is a Nix Home Manager module derived from HyDE (Arch Hyprland). Once stable, it will replace the current minimal Hyprland config.

- [ ] Import HALLwayDE module into `flake.nix` inputs
- [ ] Integrate HALLwayDE into `hosts/2600AD/home/bittermang.nix`
- [ ] Test session stability with greetd/regreet
- [ ] Migrate guest user to HALLwayDE (or subset thereof)

## 2600AD — Hyprland

- [x] Added `programs.hyprland.enable = true` to system config — registers Hyprland session with GDM
- [x] Added `services.displayManager.gdm.wayland = true` — Wayland sessions now appear in session picker
- [x] Pinned `package = pkgs.hyprland` in Home Manager — prevents version mismatch on socket
- [x] Removed redundant `xdg-desktop-portal-hyprland` from Home Manager (system module owns it)
- [x] Added XFCE as stable X11 fallback session for debugging HALLwayDE integration
- [ ] Evaluate removing GNOME once Hyprland is confirmed stable — waybar needs tray module enabled for iwgtk

## 2600AD — Networking

- [x] Replaced NetworkManager with iwd + systemd-networkd
- [x] `iwgtk` in Home Manager packages + Hyprland exec-once for WiFi tray management
- [x] Create home WiFi secret (now in `hosts/2600AD/secrets.yaml` via sops)

## Codebase Cleanup

- [ ] Delete `modules/userRoles.nix` — not imported anywhere, superseded design
- [ ] Audit `hosts/2600AD/configuration.nix` `nix-ld.libraries` — JetBrains wiki entries intermixed with Wine/Proton entries; separate and annotate clearly

## Networking — Domain Model

HALLpass.space is the WireGuard hub + Syncthing introducer for all devices (2600AD, phone). Once deployed:
- [ ] WireGuard keys populated → all devices on `10.23.11.0/24` overlay
- [ ] Syncthing relay/discovery IDs populated → file sync between 2600AD and phone routes through HALLpass.space
- [ ] DNS `2600AD.hallpass.space` → WireGuard overlay IP `10.23.11.80`
