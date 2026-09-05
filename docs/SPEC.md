# GameDevOS — Distro Specification

> Working title **GameDevOS** — rename in `config/distro.conf`.

A lean, XFCE-based Ubuntu 24.04 distribution for **.NET/C# + Godot game
development**, with a built-in **isolated sandbox layer for AI coding agents**
(powered by Warden). Scope: personal for now, with the door open to sharing later.

## Design principles
- **Barebones by default** — every package earns its place; no office suite,
  no media apps, no games.
- **Game-dev first** — .NET, Godot (C#), and asset tools are the core.
- **Safe AI agents** — hand work to AI inside sealed, disposable sandboxes.
- **No Snap** — Flatpak + Flathub is the app backbone.

## Manifest

### Foundation
| Piece | Choice |
|---|---|
| Base | Ubuntu 24.04 LTS (noble), minimal |
| Desktop | XFCE (+ LightDM) |
| Packaging | Snap **removed**; Flatpak + Flathub |
| Snapshots | btrfs + Snapper (rollback) |
| GPU | NVIDIA driver 580 (`-open` modules) + Vulkan |
| Security | ufw firewall + unattended-upgrades |

### Coding core (.NET / C#)
| Piece | Choice |
|---|---|
| SDK | .NET 10 (LTS) — `dotnet-sdk-10.0`, native in Ubuntu 24.04 repos |
| Editor | VSCode + **C# Dev Kit** + Godot Tools extension |
| Alt IDE | JetBrains Rider — optional (first-boot toggle) |
| Versions | mise (per-project toolchain pinning) |
| VCS | git + Git LFS, build-essential, dev fonts |

### Game engine
| Piece | Choice |
|---|---|
| Engine | **Godot 4.7.2 — .NET/C# ("mono") build** + export templates |

### AI-agent sandbox layer
| Piece | Choice |
|---|---|
| Engine | rootless Podman *(in base — generic containers)* |
| System | **Warden** — **isolated, opt-in** (`INCLUDE_WARDEN`), reused as-is |
| Tooling | GitHub CLI (`gh`) |

> Warden is still WIP, so it is kept out of the default build in
> [`components/warden/`](../components/warden/) and only built in when
> `INCLUDE_WARDEN="true"`. The base distro is fully functional without it.

### Creative & asset tools (Flatpak)
Blender · Krita · Pinta · Pixelorama · Audacity · Tiled

### Shell & interface
Fish + starship prompt · Standard Chromium (Flatpak) · terminal-driven app
management (no GUI store).

### Barebones utilities
curl/wget, unzip, openssh-client, htop, nano/vim, gnupg, ca-certificates.

## Build & install path
- **Primary: Cubic** (`build/build.sh` + `build/cubic-provision.sh`) — remaster
  the official **Xubuntu 24.04** ISO. Keeps Ubuntu's installer (so btrfs +
  snapshots work) and reliable boot. Fastest route to a real, installable OS.
- **Advanced: live-build** (`build/build-livebuild.sh`) — from-scratch,
  reproducible, but live-only (no installer). For experimentation.
- **Public later: Ubuntu autoinstall** (`installer/`) — the reproducible path to
  prefer if distributing; reuses Warden's `iso/` work.
- All three run the **same hooks + package lists** — the software recipe is
  builder-agnostic, so switching builders costs nothing already invested.

## Known caveats (honest status)
- **Warden is an early prototype** — so it is **isolated and opt-in**
  (`INCLUDE_WARDEN`, see `components/warden/`) and never blocks a base build.
  Enable it only when you want the sandbox workflow; its layers are still WIP.
- **btrfs root** must be set by the installer, not the image builder — see
  `installer/autoinstall.yaml` and reuse `warden/iso/`.
- **Godot C#** requires the *mono* build (handled) — the plain build can't run C#.
- **Aseprite** was dropped for licensing reasons; **Pixelorama** replaces it.
- Anything needing a running system (Flatpak apps, VSCode extensions, driver
  autodetect, Warden converge) happens in the **first-boot wizard**, not the build.

## Path to a "real" distro (later)
If this goes from personal → shareable, add: a signed update pipeline,
licensing review of bundled proprietary bits (C# Dev Kit), and broad
hardware testing. See the conversation notes.
