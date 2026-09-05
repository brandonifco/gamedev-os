# Quick-start alternative: build with Cubic

`build.sh` uses live-build (fully scripted, reproducible). If you'd rather
click through your first ISO to learn what goes in, **Cubic** is the easy path.

## Steps

1. Install Cubic on an Ubuntu machine:
   ```bash
   sudo apt-add-repository ppa:cubic-wizard/release
   sudo apt update && sudo apt install cubic
   ```
2. Download the **Ubuntu 24.04 LTS Desktop** ISO as your starting point.
3. Launch Cubic, point it at that ISO, and it drops you into a terminal
   **inside the image** (a chroot).
4. In that terminal, run the same logic our hooks do — in order. The quickest
   way is to copy this repo in and run the hooks:
   ```bash
   # from the Cubic chroot terminal:
   export BUILD_ROOT=/opt/distro-build
   mkdir -p $BUILD_ROOT && cp -r /path/to/gamedev-os/{config,packages} $BUILD_ROOT/
   for h in 0100 0200 0300 0500 0600 0700 0800; do
     bash /path/to/gamedev-os/hooks/${h}-*.sh
   done
   ```
5. Copy the first-boot pieces into place (see `build.sh` for the exact paths):
   `/opt/gamedevos/firstboot/`, `/etc/skel/.config/autostart/`.
6. Continue the Cubic wizard: pick the kernel, trim packages if you like,
   and let it generate the ISO.

## Which to use?

- **Cubic** — great for your *first* bootable ISO and for poking around.
- **live-build (`build.sh`)** — the real, rebuild-with-one-command path once
  you know what you want. This is what makes it a *distro* rather than a one-off.
