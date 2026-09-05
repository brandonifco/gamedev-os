# GameDevOS

> Working title — rename everything from `config/distro.conf`.

A lean, XFCE-based **Ubuntu 24.04** distro for **.NET/C# + Godot** game
development, with a built-in **isolated sandbox for AI coding agents** (Warden).

**Status: scaffold.** The structure and build logic are real and runnable, but
the ISO has not been built or validated on hardware yet. TODO markers flag the
spots that need a real machine/VM. See [docs/SPEC.md](docs/SPEC.md) for the full
manifest and honest caveats.

## Repo layout
```
config/distro.conf     # single source of truth (name, versions, base, toggles)
packages/              # apt + flatpak + vscode-extension lists
hooks/                 # ordered build-time chroot scripts (0100..0700)
components/warden/     # isolated, opt-in AI-sandbox layer (WIP) — off by default
firstboot/             # one-time setup wizard (runs on first login)
build/build.sh         # PRIMARY: prepare a Cubic-based ISO build
build/cubic-provision.sh # runs the hooks inside Cubic's chroot
build/CUBIC.md         # step-by-step Cubic walkthrough
build/build-livebuild.sh # ADVANCED: from-scratch live-build (live-only, reproducible)
installer/             # Ubuntu autoinstall (btrfs root) — reuse warden/iso/
docs/SPEC.md           # the agreed specification
```

## What runs when
- **Build time (hooks):** remove Snap, add MS/Flathub repos, install apt packages,
  .NET SDK + Godot, NVIDIA/Vulkan, shell + mise.
- **First boot (wizard):** install Flatpak apps, VSCode extensions, optional Rider,
  NVIDIA autodetect. *(These need a running system, so they can't happen in the
  build chroot.)*

## Warden (AI-agent sandbox) is isolated & opt-in
Warden is still WIP, so it's kept in [`components/warden/`](components/warden/) and
**left out of the default build**. The base distro builds and runs without it.
To include it, set `INCLUDE_WARDEN="true"` in `config/distro.conf` and rebuild.
Podman (generic containers) stays in the base either way.

## Build it (Cubic — recommended)
On an Ubuntu 24.04 machine (this one qualifies), Cubic remasters the official
Xubuntu ISO so you keep Ubuntu's installer and get a real, installable OS:
```bash
./build/build.sh          # installs Cubic, prints exact steps
```
Then follow [build/CUBIC.md](build/CUBIC.md): download the Xubuntu 24.04 ISO,
open it in Cubic, and run `build/cubic-provision.sh` inside its chroot.

*Advanced:* `build/build-livebuild.sh` builds from scratch (live-only, no
installer) — for reproducible/public builds, see [docs/SPEC.md](docs/SPEC.md).

## Daily use (once installed, only if Warden was enabled)
```bash
# open an isolated sandbox for an AI agent to work in
warden new myproject --repo <path-or-git-url>
warden enter myproject     # step into the sealed workspace
warden rm myproject        # tear it down when done
```

## Next steps
1. Build a first ISO (Cubic) and boot it in a VM.
2. Merge `warden/iso/` btrfs autoinstall into `installer/`.
3. Pin exact versions (.NET channel, Godot, NVIDIA branch) in `config/distro.conf`.
4. Decide personal vs shareable — the latter needs signed updates + licensing review.
