# Virtualization — rootless libvirt by default (qemu:///session): no group, no relogin,
# user-owned images under ~/.local/share/libvirt. virsh / virt-manager / virt-install / vm
# all honor this. Override per-shell with `set -x LIBVIRT_DEFAULT_URI qemu:///system`.
set -gx LIBVIRT_DEFAULT_URI qemu:///session
