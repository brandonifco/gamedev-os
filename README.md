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
build/build.sh         # build the ISO with live-build
build/CUBIC.md         # easier GUI alternative for your first ISO
installer/             # subiquity autoinstall (btrfs root) — reuse warden/iso/
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

## Build it
On an Ubuntu 24.04 build host:
```bash
sudo apt install live-build debootstrap
./build/build.sh
```
The ISO lands in `.build/`. First time? Read [build/CUBIC.md](build/CUBIC.md) for
the click-through approach instead.

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
