#!/usr/bin/env bash
# SlicedLabs OS — archiso profile. build.sh COPIES the installed releng template, then
# overlays THIS file, the airootfs first-boot hook, and a merged package list. Keep the
# technical fields (bootmodes/compression/permissions) in sync with the local releng's
# profiledef.sh so the profile stays valid across archiso releases; only the branding +
# the first-boot script permission are SlicedLabs-specific.
# shellcheck disable=SC2034

iso_name="slicedlabs-os"
iso_label="SLICEDLABS_$(date +%Y%m)"
iso_publisher="SlicedLabs <https://github.com/SL1C3D-L4BS>"
iso_application="SlicedLabs OS — Liquid-Glass · a governed AI team"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/slicedlabs-firstboot.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
