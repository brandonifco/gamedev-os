# components/warden — isolated, opt-in

Warden is the AI-agent sandbox layer (`warden new/enter/rm`). It lives **outside**
the default build on purpose: it's still a work in progress upstream, and the base
distro must build and run without depending on it.

## Enable it
Set in [`../../config/distro.conf`](../../config/distro.conf):
```sh
INCLUDE_WARDEN="true"
```
Then rebuild. `build.sh` will inject `install-warden.sh` as build hook `0800`.
When disabled (the default), none of this runs and nothing references Warden.

## What it does when enabled
- installs Ansible (Warden's provisioner) — kept here, not in the base
- clones https://github.com/brandonifco/warden into `/opt/warden`
- first-boot wizard then offers to converge it (off by default)

## What stays in the base regardless
Podman + rootless container plumbing live in `packages/apt-base.list`. That's a
generic capability, not Warden-specific, so it stays even with Warden disabled.

## Promoting Warden later
When Warden is stable enough to be a first-class part of the distro, either flip
the default to `"true"`, or fold these steps back into `hooks/` as a numbered hook.
Until then, keep it here so its rough edges can't block a base build.
