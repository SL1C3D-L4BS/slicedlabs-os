# RUNBOOK — Virtualization (libvirt/KVM) in the coding command center

Rootless **`qemu:///session`** libvirt/KVM. No libvirt group, no relogin, no system
daemon at boot — the per-user `virtqemud` is auto-exec'd on first `virsh`, images live
under `~/.local/share/libvirt`. The VM is the 3rd cockpit of the coding command center
(CODE · AI · **VM**), summoned on demand (never auto-booted — OOM-safe).

## Quickstart
```bash
vm list                 # domains + state
coding-vm               # focus coding + boot the Arch sandbox, console on coding
coding-vm iso           # …or dogfood the SlicedLabs OS ISO     (Mod+Ctrl+Shift+V = coding-vm)
vm iso                  # boot + console slicedlabs-iso (any workspace)
vm sandbox              # boot + console the persistent Arch sandbox
vm gui                  # virt-manager (GUI), connected to qemu:///session
vm --help               # everything
```

## Domains (defined by `vm ensure`, run from `bootstrap.sh --layer V`)
| Domain | Purpose | Shape |
|---|---|---|
| `slicedlabs-iso` | Dogfood the built OS ISO (P10 live half) | UEFI, no disk, CD-ROM = `iso/out/slicedlabs-os-*.iso`, `--livecd` |
| `arch-sandbox` | Persistent Arch sandbox / agent sandbox | 40G qcow2 + **virtiofs share of `~/Projects`** (tag `projects`), 8G/4vCPU |
| *(yours)* | Cross-platform guest | `vm create <name> <install.iso> [disk_gb]` |

In-guest, mount the shared `~/Projects`: `mount -t virtiofs projects /mnt`.
First sandbox boot lands in the ISO installer (boot order cdrom→hd); install, then it
boots the disk. Snapshot before risky work: `vm snapshot arch-sandbox`.

## Architecture (the "2026" choices + the sharp edges we filed off)
- **Rootless session libvirt** — frictionless + OOM-safe; override with
  `LIBVIRT_DEFAULT_URI=qemu:///system` for bridged networking later.
- **UEFI via the NON-secure OVMF** (`OVMF_CODE.4m.fd`) — the ISO isn't signed yet
  (secure-boot is deferred P10; the `.secboot` firmware would refuse the unsigned loader).
- **swtpm TPM2** (`tpm-crb`), **virtio-gpu + SPICE** console (virt-viewer), **passt**
  usermode networking (outbound NAT, rootless).
- **`virt-install` runs under `/usr/bin/python3`** — mise's python3 lacks PyGObject
  (`gi`); `virsh`/`virt-viewer` are C binaries so START + console are unaffected.
- **`audio` backend forced to `none`** — qemu 11.0.1 SIGSEGVs initializing the SPICE
  audio backend; these guests need no audio. (Guarded by `verify-vm.sh`.)

## Verify
`verify-vm.sh` (in `verify-all`) — non-destructive: KVM, session reachable, both domains
defined + KVM/OVMF/TPM/audio=none, virtiofs wired, ISO present. Never boots a guest.

## Deferred (P10 tail)
Secure-boot **signing** + key enrollment (then flip to `OVMF_CODE.secboot.4m.fd`),
a Nix/home-manager module, the flagship install docs.
