# Building the ISO with live-build (advanced path)

Debian **live-build** builds the image from scratch (Ubuntu *noble* base) and is
fully **scriptable/headless** — no GUI, unlike [Cubic](CUBIC.md). The trade-off:
it produces a **live-only ISO with no installer**, so it can't set up the btrfs
root that Snapper snapshots depend on. Use it for reproducible experimentation
and CI; use Cubic (or `installer/` autoinstall) when you need a real installable OS.

Driver script: [`build/build-livebuild.sh`](build-livebuild.sh).
Output: `.build/live-image-amd64.iso` (grub2 BIOS live ISO).

## 1. Requirements
On an **Ubuntu 24.04** build host:
```bash
sudo apt-get update && sudo apt-get install -y live-build debootstrap
```
You also need: `sudo`, network access to `archive.ubuntu.com` and the pinned
artifacts (Godot, MS repo, starship, mise, Flathub), and ~10–15 GB free disk.
The build runs unattended but takes ~20–40 min (debootstrap + apt + our hooks).

## 2. Build
```bash
./build/build-livebuild.sh          # cleans .build/, stages config, runs `sudo lb build`
```
The script:
1. `sudo rm -rf .build` and recreate the workspace.
2. `lb config` (see options below).
3. Stage `config/` + `packages/` into the chroot at `/opt/distro-build`, seed the
   first-boot wizard into `/opt/gamedevos` and `/etc/skel`, install the ordered
   hooks, and write the XFCE desktop package list.
4. `sudo lb build` — bootstrap the base, run hooks, assemble the hybrid ISO.

Warden is injected as hook `0800` only when `INCLUDE_WARDEN="true"` in
`config/distro.conf`; otherwise it's a base-only build.

## 3. `lb config` options (what the script passes, and why)
| Option | Value | Why |
|---|---|---|
| `--distribution` | `noble` (`$BASE_SUITE`) | Ubuntu 24.04 LTS base. |
| `--archive-areas` | `main restricted universe multiverse` | NVIDIA/firmware live in restricted/multiverse. |
| `--mirror-bootstrap` / `--mirror-binary` | `$BASE_MIRROR` | Ubuntu archive mirror. |
| `--architectures` | `amd64` (`$ARCH`) | Target arch. |
| `--debian-installer` | `false` | **Disable the installer** → live-only image. See gotcha below. |
| `--bootloader` | `grub2` | Use GRUB 2 (BIOS + EFI), not syslinux. Avoids the missing gfxboot theme — see gotcha below. |
| `--bootappend-live` | `boot=live components hostname=$DISTRO_ID` | Kernel cmdline for the live session. |

To tweak the recipe, edit `config/distro.conf` (single source of truth) rather
than the script — the values above are read from it.

## 4. Version gotchas (Ubuntu's live-build `3.0~aXX`)
Ubuntu ships an older live-build than current Debian. Two conventions differ, and
`build-livebuild.sh` is written for **Ubuntu's** version:

- **Local hooks must be at `config/hooks/*.chroot`** (top level, non-recursive).
  The newer Debian `config/hooks/normal/` and `config/hooks/live/` subdirectories
  are **not scanned** — hooks placed there run *never* and produce a base image
  with none of our software, silently. The script installs to `config/hooks/`.
- **`--debian-installer` accepts only** `true|cdrom|netinst|netboot|businesscard|live|false`.
  Passing `none` (a value some docs mention) fails ISO assembly with
  `E: debian-installer flavour none not supported.` Use `false` to disable it.
- **`--bootloader grub2`, not the default `syslinux`.** The syslinux binary stage
  pulls `gfxboot-theme-ubuntu` for its boot menu, which noble no longer ships, so
  the default fails with `E: Package 'gfxboot-theme-ubuntu' has no installation
  candidate`. Use **`grub2`** (modern GRUB, BIOS + UEFI) — **not `grub`**, which in
  live-build means legacy GRUB 0.97 (`grub-legacy`, absent from noble →
  `no installation candidate`). `lb_binary_syslinux` cleanly no-ops when the
  bootloader isn't syslinux.

- **`isohybrid` needs `syslinux-utils` in the chroot.** With `LB_BUILD_WITH_CHROOT=true`,
  the ISO stage runs `isohybrid` (makes the image USB-bootable) *inside* the chroot,
  but tries to provide it via the `syslinux` package — on noble `isohybrid` moved to
  `syslinux-utils`, so the build dies at the very end with `isohybrid: not found`.
  The script ships `syslinux-utils` (and `genisoimage`) via
  `config/package-lists/isotools.list.chroot` so it's present when the ISO is assembled.
- **`--binary-images iso`, not the default `iso-hybrid`, when using grub2.** `isohybrid`
  is a syslinux tool: on a grub2 ISO it fails with `boot loader does not have an
  isolinux.bin hybrid signature`, aborting before the final `.iso` is emitted. Setting
  `iso` skips the isohybrid step (`lb_binary_iso` only runs it for `iso-hybrid`). The
  cost: the image is **BIOS-boot only** (this live-build's grub2 branch builds just the
  i386-pc El Torito image, no EFI), and not raw-`dd`-able to USB — fine for VM testing;
  use Cubic for UEFI + an installer. Output is `live-image-amd64.iso` (not `.hybrid.iso`).

If you upgrade to a newer live-build, re-check these against
`/usr/lib/live/build/lb_chroot_hooks`, `.../lb_binary_debian-installer`,
`.../lb_binary_syslinux`, and `.../lb_binary_iso`.

## 5. Rebuild / clean
`build-livebuild.sh` already cleans `.build/` on every run, so just re-run it.
To clean manually (chroot files are root-owned):
```bash
sudo rm -rf .build      # full reset
# or, inside .build/:  sudo lb clean --purge
```
Our hooks run during the **chroot** stage, so any change to a hook or package list
requires a full rebuild (a binary-only re-run won't re-execute them).

## 6. Test it
The result is **live-only** — boot it in a VM to try the desktop, but you can't
"install" it to disk from this image:
```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -cdrom .build/live-image-amd64.iso -boot d
```
(or GNOME Boxes / virt-manager). For an installable OS with a btrfs root, use the
[Cubic path](CUBIC.md) instead.
