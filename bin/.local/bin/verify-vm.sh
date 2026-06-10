#!/usr/bin/env bash
# SlicedLabs · tools · © 2026 SlicedLabs
# verify-vm — the coding command center's virtualization invariants (rootless
# qemu:///session). Non-destructive: NEVER boots a guest. Wire into verify-all (opt).
# Exits 0 (clean opt-out) if libvirt isn't installed yet, so partial builds still pass.
set -uo pipefail
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///session}"
fail=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$*"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$*" >&2; fail=1; }

command -v virsh >/dev/null 2>&1 || { echo "vm: libvirt not installed — skipping (bootstrap.sh --layer V)"; exit 0; }

[ -e /dev/kvm ] && ok "/dev/kvm present (KVM acceleration)" || no "/dev/kvm missing"
virsh uri >/dev/null 2>&1 && ok "libvirt session reachable ($(virsh uri 2>/dev/null))" \
    || no "cannot reach libvirt (qemu:///session)"

for d in slicedlabs-iso arch-sandbox; do
    if ! virsh dominfo "$d" >/dev/null 2>&1; then no "domain missing: $d (run: vm ensure)"; continue; fi
    ok "domain defined: $d"
    x="$(virsh dumpxml "$d" 2>/dev/null)"
    grep -q "domain type='kvm'"             <<<"$x" && ok "$d: KVM-accelerated"                   || no "$d: not KVM (type!=kvm)"
    grep -q "OVMF_CODE.4m.fd"               <<<"$x" && ok "$d: UEFI via non-secure OVMF"          || no "$d: not the non-secure OVMF"
    grep -q "<tpm"                          <<<"$x" && ok "$d: TPM2 present"                      || no "$d: no TPM"
    grep -q "audio id='1' type='none'"      <<<"$x" && ok "$d: audio=none (qemu-11 crash guard)"  || no "$d: audio not 'none' — will SIGSEGV"
done

[ -f /usr/share/edk2/x64/OVMF_CODE.4m.fd ] && ok "OVMF firmware present" || no "OVMF_CODE.4m.fd missing (edk2-ovmf)"
command -v swtpm >/dev/null 2>&1 && ok "swtpm present" || no "swtpm missing"
virsh dumpxml arch-sandbox 2>/dev/null | grep -q "driver type='virtiofs'" \
    && ok "arch-sandbox: virtiofs share wired" || no "arch-sandbox: no virtiofs share"

iso="$(virsh dumpxml slicedlabs-iso 2>/dev/null | grep -oE "/[^']*slicedlabs-os-[^']*\.iso" | head -1)"
{ [ -n "$iso" ] && [ -f "$iso" ]; } && ok "slicedlabs-iso → $(basename "$iso")" \
    || no "slicedlabs-iso cdrom missing or file absent"

[ $fail -eq 0 ] && echo "vm: virtualization invariants intact ✓"
exit $fail
