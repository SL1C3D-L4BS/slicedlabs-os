# SlicedLabs OS — installable ISO

A live/showcase archiso profile: boot it (VM or USB) → it clones the **public**
showcase repo, runs the idempotent `bootstrap.sh`, and drops you into the niri +
Cockpit desktop with `slicedlabs welcome`. The replicability ladder's "Try" rung —
zero risk to the host.

## Build (in a clean Arch container/VM, as root)

```bash
sudo pacman -S archiso
cd iso
sudo ./build.sh          # regenerates packages.x86_64 from snapshot-packages, runs mkarchiso
# → out/slicedlabs-os-YYYY.MM.DD-x86_64.iso
```

## Try it (qemu)

```bash
qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -cdrom out/*.iso
```

## What's here

| File | Role |
|---|---|
| `profiledef.sh` | archiso profile (name, bootmodes, permissions). Align field names with the installed archiso `releng` template if a build errors. |
| `build.sh` | mkarchiso wrapper; bakes `packages.x86_64` = `packages.base` + `snapshot-packages --explicit`. |
| `packages.base` | live-ISO essentials + the desktop (niri/quickshell/…) so the live env *is* SlicedLabs OS. |
| `airootfs/root/.zlogin` → `slicedlabs-firstboot.sh` | first-boot: clone public repo → bootstrap → niri/Cockpit + `slicedlabs welcome`. |

## Guarantees

- The first-boot clones the **public** repo (`SLICEDLABS_REPO`), never the private
  control-plane — run `verify-public-clean` on that repo before publishing.
- `slicedlabs-os doctor` (every `verify-*` gate + service health) is the post-install
  green check; the ISO's first-boot can call it to self-verify.

## Still to wire (handed off — needs the build host)

- ~~A first `mkarchiso` run to confirm the profile builds, then a VM boot test.~~
  **Done** — the ISO is built (`out/slicedlabs-os-2026.06.01-x86_64.iso`) and **boots
  in the libvirt/KVM VM** under OVMF (UEFI): `vm iso` / `coding-vm iso` (see
  `docs/RUNBOOK-vm.md`). The `slicedlabs-iso` domain is the standing dogfood target.
- Optional: a `systemd-boot` splash + the Plymouth `slicedlabs-plymouth boot` step baked in.
- A flagship `README.md` + `docs/SYSTEM-MAP.md` + a Nix/home-manager module for the
  declarative install path (DMS-style).
- **Secure boot (P10 tail):** sign the bootloader/kernel + enroll keys, then point the VM
  at `OVMF_CODE.secboot.4m.fd` (the `vm` script defaults to the non-secure OVMF today so
  the unsigned ISO boots).
