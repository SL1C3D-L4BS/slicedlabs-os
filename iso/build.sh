#!/usr/bin/env bash
# build.sh — build the SlicedLabs OS live ISO by OVERLAYING the SlicedLabs profile
# onto the installed archiso `releng` template (so bootloaders + pacman.conf stay in
# sync with the local archiso, robust to releng field drift). Run on Arch as root:
#
#   sudo pacman -S archiso && cd iso && sudo ./build.sh
#
# Package model (the "Try" rung — a LEAN official base that bootstraps into the full
# desktop): packages.x86_64 = packages.base filtered to OFFICIAL-repo packages only,
# because mkarchiso uses official pacman and cannot build AUR. The AUR desktop
# (quickshell, swaylock-effects, …) + the whole curated stack install on FIRST BOOT
# via bootstrap.sh (paru). So the ISO stays small and fast to build; first boot
# clones the public showcase repo and runs the idempotent bootstrap.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-/tmp/slicedlabs-iso/work}"
OUT="${OUT:-$HERE/out}"
RELENG="${RELENG:-/usr/share/archiso/configs/releng}"

command -v mkarchiso >/dev/null || { echo "install archiso first: pacman -S archiso" >&2; exit 1; }
[ -d "$RELENG" ] || { echo "releng template missing: $RELENG" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo ./build.sh)" >&2; exit 1; }

PROFILE="$WORK/profile"
rm -rf "$WORK"; mkdir -p "$WORK" "$OUT"
cp -a "$RELENG" "$PROFILE"

# Overlay the SlicedLabs profile bits onto the releng base.
cp -a "$HERE/profiledef.sh" "$PROFILE/profiledef.sh"
cp -a "$HERE/airootfs/." "$PROFILE/airootfs/"

# packages.x86_64 = packages.base ∩ ARCH-official repos (core/extra/multilib). This
# host is CachyOS, but the ISO builds on the stock archiso/releng pacman.conf, so
# cachyos-repo + AUR packages (quickshell-git, swaylock-effects, …) are dropped here
# and installed on FIRST BOOT by bootstrap.sh (paru builds them from AUR). The live
# base ships niri + ghostty (both in Arch extra), so it boots to a real compositor.
pacman -Sy --noconfirm >/dev/null
# Merge releng's live essentials (syslinux, memtest86+, edk2-shell, mkinitcpio-archiso,
# …) with the SlicedLabs desktop from packages.base, then keep only Arch-official names.
{ cat "$PROFILE/packages.x86_64"; grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$HERE/packages.base"; } \
  | sort -u | comm -12 - <(pacman -Slq core extra multilib | sort -u) > "$PROFILE/packages.x86_64.tmp"
mv "$PROFILE/packages.x86_64.tmp" "$PROFILE/packages.x86_64"
echo "→ packages.x86_64: $(wc -l < "$PROFILE/packages.x86_64") Arch-official packages (releng base + SlicedLabs desktop; cachyos/AUR → first-boot bootstrap)"

mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
echo "✓ ISO in $OUT — boot in a VM: qemu-system-x86_64 -enable-kvm -m 4G -cdrom $OUT/*.iso"
