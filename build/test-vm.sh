#!/bin/bash
# Boot the custom ISO in a QEMU/KVM VM (UEFI, like real hardware) to test it.
#
# Usage:
#   ./build/test-vm.sh [path-to.iso]
# With no argument it picks the newest ISO in ~/cubic-gamedevos/.
#
# The virtual disk persists in ~/gamedevos-vm/ so you can install, reboot, and
# come back to your installed system. Delete that folder to start fresh.
set -euo pipefail

ISO="${1:-$(ls -t "$HOME"/cubic-gamedevos/*.iso 2>/dev/null | head -1 || true)}"
if [ -z "${ISO:-}" ] || [ ! -f "$ISO" ]; then
  echo "No ISO found. Pass the path explicitly:  $0 /path/to/your.iso"
  exit 1
fi

VMDIR="$HOME/gamedevos-vm"
DISK="$VMDIR/disk.qcow2"
VARS="$VMDIR/OVMF_VARS.fd"
mkdir -p "$VMDIR"
[ -f "$DISK" ] || { echo ">> creating 40G virtual disk"; qemu-img create -f qcow2 "$DISK" 40G; }
[ -f "$VARS" ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"

echo ">> booting VM with ISO: $ISO"
echo ">> (a QEMU window will open; install to the virtual disk, choosing your options)"
exec qemu-system-x86_64 \
  -enable-kvm -machine q35 -cpu host -smp 4 -m 6144 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file="$VARS" \
  -drive file="$DISK",if=virtio,format=qcow2 \
  -cdrom "$ISO" \
  -boot menu=on \
  -vga virtio -display gtk \
  -device qemu-xhci -device usb-tablet \
  -netdev user,id=n0 -device virtio-net,netdev=n0 \
  -name "GameDevOS test VM"
