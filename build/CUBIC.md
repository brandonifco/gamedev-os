# Building the ISO with Cubic (primary path)

Cubic remasters an official Ubuntu-family ISO, so the result **keeps Ubuntu's
installer and boot machinery** — you get a real, installable OS (with btrfs
support) quickly and reliably. This is the recommended way to build your first
image.

## 1. Install Cubic
`build/build.sh` does this for you:
```bash
./build/build.sh
```
(or manually: `sudo add-apt-repository ppa:cubic-wizard/release && sudo apt install cubic`)

## 2. Get the base ISO
Download **Xubuntu 24.04 LTS** — it's already XFCE, matching your desktop choice,
and is leaner than Ubuntu Desktop:
- https://xubuntu.org/download/

## 3. Provision inside Cubic
1. Launch Cubic, select the Xubuntu ISO, and step forward until Cubic drops you
   into a **terminal inside the image** (a chroot).
2. Get this repo into the chroot (Cubic's "copy file" feature, or scp/mount it),
   e.g. to `/root/gamedev-os`.
3. Run the provisioner:
   ```bash
   bash /root/gamedev-os/build/cubic-provision.sh
   ```
   This runs every build hook (remove Snap, add repos, install apt packages,
   .NET + Godot, NVIDIA/Vulkan, shell + mise) and seeds the first-boot wizard.
   Warden is included only if `INCLUDE_WARDEN="true"` in `config/distro.conf`.
4. Type `exit` to leave the chroot.

## 4. Finish the wizard
Continue Cubic: pick the kernel, optionally trim packages Cubic lists, and let it
generate the ISO.

## 5. Test it
Boot the ISO in a VM (GNOME Boxes, virt-manager, or VirtualBox) and install it.
**Choose a btrfs root** during install so Snapper snapshots/rollback work.

---

## When to use the other paths instead
- **`build-livebuild.sh`** — a from-scratch, fully reproducible build. Live-only
  (no installer), finicky on Ubuntu. For advanced/experimental use.
- **`installer/` (Ubuntu autoinstall)** — the reproducible path to prefer if you
  go public: no custom live ISO, Ubuntu's own installer converges from a recipe.
  Reuses Warden's `iso/` work.
