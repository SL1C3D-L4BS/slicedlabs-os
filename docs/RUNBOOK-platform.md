# RUNBOOK — Platform (P11): atomic rollback · capability sandbox · scene‑DSL · UKI

The OS-resilience layer beneath the desktop. Gate: `verify-platform` (in `verify-all`).

## Atomic rollback (btrfs + snapper + snap-pac)
Root + home are btrfs with snapper configs; **snap-pac** brackets *every* pacman
transaction with a pre/post snapshot — so any update is atomically reversible.
```bash
snapper -c root list                  # timeline + the pre/post pairs around each pacman run
snapper -c root undochange A..B        # revert the file changes of one transaction
sudo snapper -c root rollback N        # promote snapshot N to the new default (full atomic rollback)
```
Boot is **UKI** (`mkinitcpio default_uki` → `/boot/EFI/Linux/*.efi`, auto-discovered by
systemd-boot — no `loader/entries`). A bad kernel/initramfs is just a previous UKI away.

## Capability sandbox (agent CPU/mem cgroup — the hard floor under Warden)
`sl-agents.slice` caps autonomous agents at **4 threads / 12 GiB**, low CPU weight, so a
runaway crew can never starve the interactive desktop. Warden *surfaces/benches*; the
kernel *enforces*.
```bash
sl-sandbox <cmd…>                      # run anything inside the slice (e.g. sl-sandbox slicedlabs crew …)
slc-claude --as <role>                 # autonomous identities auto-run in the slice
SL_SANDBOX=1 slc-claude                 # opt the interactive editor in too;  SL_SANDBOX=0 opts out
systemctl --user show sl-agents.slice -p CPUQuotaPerSecUSec -p MemoryMax
```
The interactive editor's `claude` (identity `claude`) stays **unconstrained** for snappiness.

## Scene-DSL (the workspaces.toml registry)
`workspaces.toml` is the declarative scene DSL read by `lib/scene.sh`. `verify-scenes`
validates it (outputs/layouts/tiling enums, `meta.auto` references, unique app_ids, integer
columns, required per-app fields) — drift is caught here, not as a silently-unstaged window.

## Secure Boot (P10) — signed, ready, activate knowingly
Boot is UKI on systemd-boot. `sbctl` signs the bootloader + UKIs (+ fallback + EFISTUB
kernels) with locally-generated keys. **Signing is inert while SB is off** — `secureboot
setup` does not change how the machine boots today; it just makes it *ready*.
```bash
secureboot setup      # create keys + sign all EFI binaries (idempotent; re-signs on updates)
secureboot status     # sbctl status + SB/Setup-Mode + signed-file list
```
**Activating SB is a deliberate, brick-aware firmware step — not automated:**
1. `secureboot status` → confirm everything is signed.
2. Reboot → firmware → **clear Secure Boot keys / enter Setup Mode** (vendor-specific).
3. Back in the OS: `secureboot enroll` (guarded — refuses unless Setup Mode; enrolls our
   keys + Microsoft's so signed option-ROMs still work).
4. Reboot → firmware → **enable Secure Boot**. If anything is unsigned it won't boot —
   `secureboot status` first. Recovery if it ever fails: disable SB in firmware (boots
   again, since the UKIs are unchanged), fix, retry.

Test the chain risk-free in a VM first: the libvirt domains can use the `.secboot` OVMF
(`/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd`) — enroll + enable inside the guest, never
the host. Declarative install path: `nix/flake.nix` + `nix/home.nix` (home-manager).

## Reverse it
Atomic: `pacman -R snap-pac`. Sandbox: remove `~/.config/systemd/user/sl-agents.slice` +
`systemctl --user daemon-reload` (slc-claude falls back to a direct exec). All git-tracked.
