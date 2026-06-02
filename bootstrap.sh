#!/usr/bin/env bash
# bootstrap.sh — reproducible development pipeline for the Founder workstation.
#
# Idempotent layered installer. Every step is guarded by `command -v`,
# `pacman -Qi`, or a write-once sentinel, so re-runs are no-ops.
#
# Layers fall into three eras:
#   0–8   baseline workstation (Arch+Niri+Wayland, languages, A/V, appearance)
#   B–K   2026 polyglot senior-engineer stack (Python, data, obs, k3d, AI,
#         security, TUI, Pomodoro, Niri/Waybar wire-up, book list)
#   L–R   personal AI team (knowledge ingestion, Mem0, Langfuse, agent roster,
#         n8n, Obsidian/Cognee, prompt CI)
#
# Usage:
#   ./bootstrap.sh                # full bootstrap (recommended after `stow`)
#   ./bootstrap.sh --list         # print layer roster
#   ./bootstrap.sh --layer 0      # run a single layer (matches by id token)
#   ./bootstrap.sh --layer B C D  # run several layers in given order
#   ./bootstrap.sh --dry-run …    # show what would run without doing it
#   ./bootstrap.sh --skip H       # full run, but skip the AI install layer
#   ./bootstrap.sh --from F       # full run starting from layer F
#
# Conventions:
#   - `paru` is the AUR helper (already required by Layer 0).
#   - Each layer is a function named `layer_<id>_<slug>()`.
#   - Heavy installs (model pulls, k3d, ROCm) emit timing summaries.
#
# Order rationale (matches the plan's recommended path):
#   A → 0..8 → B → C → E → D → F → G → I → H → J → K → L → M → N → R → O → Q → P
# (A is the dotfiles scaffolding step — files already in tree by the time
# this script runs.)
set -euo pipefail

# --------------------------------------------------------------------------- #
# Logging                                                                     #
# --------------------------------------------------------------------------- #
log()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
sub()  { printf '   \033[1;34m·\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m!!  %s\033[0m\n' "$*"; }
err()  { printf '\n\033[1;31m??  %s\033[0m\n' "$*" >&2; }

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
DRY_RUN="${DRY_RUN:-0}"
COMPOSE="${COMPOSE:-$DOTFILES_ROOT/podman-compose}"
SENTINELS="$HOME/.cache/bootstrap"
mkdir -p "$SENTINELS"

run() {
  if [[ "$DRY_RUN" == 1 ]]; then printf '     would: %s\n' "$*"; return 0; fi
  "$@"
}

# Idempotent package install helpers (no-ops on already-installed).
pac() { sudo pacman -S --noconfirm --needed "$@"; }
aur() { paru -S --noconfirm --needed "$@"; }

# Sentinel file gating: `sentinel <name> <work…>` runs the work only the first
# time and on subsequent runs becomes a no-op.
sentinel() {
  local name="$1"; shift
  local marker="$SENTINELS/$name.done"
  if [[ -f "$marker" ]]; then sub "[sentinel $name] skip — already done"; return 0; fi
  "$@"
  if [[ "$DRY_RUN" == 0 ]]; then touch "$marker"; fi
}

# --------------------------------------------------------------------------- #
# LAYER 0 · system baseline                                                   #
# --------------------------------------------------------------------------- #
layer_0_baseline() {
  log "Layer 0 — system upgrade + build infrastructure"
  run sudo pacman -Syu --noconfirm --needed \
    ninja meson pkgconf autoconf automake libtool m4 patch \
    ccache lld llvm clang \
    ripgrep fd bat eza git-delta lazygit fzf tealdeer \
    direnv pre-commit shellcheck shfmt yq \
    unzip p7zip rsync openssh nss-mdns
  run aur mise
}

# --------------------------------------------------------------------------- #
# LAYER 1 · polyglot language toolchains                                      #
# --------------------------------------------------------------------------- #
layer_1_languages() {
  log "Layer 1 — language toolchains"
  run pac nasm yasm \
        lldb valgrind bear cppcheck doxygen \
        uv python-pipx ruff \
        jdk-openjdk maven gradle \
        lua luajit luarocks
  run aur zls kotlin

  eval "$(mise activate bash)"
  run mise use -g go@latest zig@latest node@lts ruby@latest
  run mise reshim
  command -v corepack >/dev/null 2>&1 && run corepack enable || true
  run npm install -g typescript
  run go install golang.org/x/tools/gopls@latest
  run go install github.com/go-delve/delve/cmd/dlv@latest
  command -v gem >/dev/null 2>&1 && run gem install bundler || true
}

# --------------------------------------------------------------------------- #
# LAYER 2 · cross-compilation toolchains                                      #
# --------------------------------------------------------------------------- #
layer_2_cross() {
  log "Layer 2 — cross-compilation targets"
  run pac mingw-w64-gcc mingw-w64-binutils mingw-w64-crt mingw-w64-headers \
          mingw-w64-winpthreads wine binaryen wasmtime
  run aur aarch64-linux-gnu-gcc cargo-xwin
  run rustup target add \
    x86_64-pc-windows-gnu x86_64-pc-windows-msvc \
    wasm32-unknown-unknown wasm32-wasip1 \
    aarch64-unknown-linux-gnu aarch64-apple-darwin x86_64-apple-darwin

  if [[ ! -x "$HOME/tools/osxcross/target/bin/aarch64-apple-darwin25-clang" ]]; then
    local sdk
    sdk=$(ls -1 "$HOME"/Resources/sdks/MacOSX*.sdk.tar.xz 2>/dev/null | sort -V | tail -1 || true)
    if [[ -n "$sdk" ]]; then
      sub "building osxcross from $(basename "$sdk")"
      run mkdir -p "$HOME/tools"
      [[ -d "$HOME/tools/osxcross/.git" ]] || \
        run git clone --depth=1 https://github.com/tpoechtrager/osxcross.git "$HOME/tools/osxcross"
      run cp -n "$sdk" "$HOME/tools/osxcross/tarballs/"
      ( cd "$HOME/tools/osxcross" && run env UNATTENDED=1 ./build.sh )
    else
      warn "no macOS SDK at ~/Resources/sdks/MacOSXNN.sdk.tar.xz — osxcross not built"
    fi
  fi
}

# --------------------------------------------------------------------------- #
# LAYER 3 · MacBook Air client tooling                                        #
# --------------------------------------------------------------------------- #
layer_3_mac_air_client() {
  log "Layer 3 — MacBook Air client tooling"
  run aur mutagen.io-bin remmina
  [[ -f "$HOME/.ssh/mac_ed25519" ]] || \
    run ssh-keygen -t ed25519 -q -N "" -f "$HOME/.ssh/mac_ed25519" \
      -C "founder-workstation->macbook-air (LAN build node)"
}

# --------------------------------------------------------------------------- #
# LAYER 4 · Rust developer tooling                                            #
# --------------------------------------------------------------------------- #
layer_4_rust_tooling() {
  log "Layer 4 — cargo extensions"
  run pac cargo-nextest cargo-deny cargo-audit cargo-semver-checks \
          cargo-llvm-cov cargo-flamegraph cargo-expand bacon cross sccache \
          wasm-pack wasm-bindgen
}

# --------------------------------------------------------------------------- #
# LAYER 5 · containers & virtualization                                       #
# --------------------------------------------------------------------------- #
layer_5_containers() {
  log "Layer 5 — Podman + distrobox"
  run pac podman podman-compose buildah distrobox \
          qemu-user-static qemu-user-static-binfmt
  run systemctl --user enable --now podman.socket
}

# --------------------------------------------------------------------------- #
# LAYER 6 · A/V capture stack (streaming + recording)                         #
# --------------------------------------------------------------------------- #
layer_6_av_capture() {
  log "Layer 6 — A/V capture stack"
  run pac obs-studio obs-studio-plugin-browser obs-vkcapture \
          v4l2loopback-dkms \
          pavucontrol qpwgraph easyeffects lsp-plugins
  run sudo install -m 0644 "$DOTFILES_ROOT/system/etc/modprobe.d/v4l2loopback.conf" \
        /etc/modprobe.d/v4l2loopback.conf
  run sudo install -m 0644 "$DOTFILES_ROOT/system/etc/modules-load.d/v4l2loopback.conf" \
        /etc/modules-load.d/v4l2loopback.conf
  run sudo modprobe v4l2loopback || true

  # Music: mpd + mpc + rmpc (gorgeous TUI) + mpd-mpris (MPRIS -> Waybar media HUD)
  # + mpv. Minimal, FOSS, no-distraction; local library (~/Music) + radio (`music`).
  run pac mpd mpc mpv mpv-mpris rmpc mpd-mpris
  # NOT enabled at boot — the `music` command (Mod+Alt+P) starts mpd + mpd-mpris on demand.
}

# --------------------------------------------------------------------------- #
# LAYER 7 · appearance: GTK dark + fonts + Firefox policy + ricing daemons    #
# --------------------------------------------------------------------------- #
layer_7_appearance() {
  log "Layer 7 — appearance: GTK dark + enterprise dark policy"
  run sudo install -D -m 0644 "$DOTFILES_ROOT/system/etc/firefox/policies/policies.json" \
        /etc/firefox/policies/policies.json
  command -v gsettings >/dev/null 2>&1 && {
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    run gsettings set org.gnome.desktop.interface gtk-theme    'Adwaita-dark' || true
  }
  run pac ttf-jetbrains-mono-nerd ttf-geist-mono bibata-cursor-theme \
          tela-circle-icon-theme-purple qt6ct mako wofi swayidle swaybg
  run aur swaylock-effects
}

# --------------------------------------------------------------------------- #
# LAYER 8 · creator toolkit                                                   #
# --------------------------------------------------------------------------- #
layer_8_creator_toolkit() {
  log "Layer 8 — creator toolkit"
  run pac imagemagick inkscape jq yt-dlp
}

# =========================================================================== #
# 2026 POLYGLOT SENIOR-ENGINEER STACK                                         #
# =========================================================================== #

# --------------------------------------------------------------------------- #
# LAYER B · Python ecosystem (L2/L3 in the layered architecture)              #
# uv-everywhere; manim/PyTorch/Transformers/LangChain via `uv tool install`   #
# --------------------------------------------------------------------------- #
layer_B_python_ecosystem() {
  log "Layer B — Python ecosystem"

  # System deps (manim needs LaTeX + ffmpeg + Pango)
  run pac python python-pipx ffmpeg \
          texlive-most texlive-fontsutils pango cairo \
          libffi openssl

  # mise installs (pins are in mise/.config/mise/config.toml)
  eval "$(mise activate bash)"
  run mise install
  run mise reshim

  # Refresh PATH inside this shell so the newly-installed uv / python are
  # visible to subsequent `uv tool install` calls below.
  export PATH="$HOME/.local/share/mise/shims:$PATH"

  # uv tool installs from system/python-stack.txt
  local stack="$DOTFILES_ROOT/system/python-stack.txt"
  if [[ -f "$stack" ]]; then
    local tool
    while IFS= read -r line; do
      tool="${line%%#*}"; tool="${tool//[[:space:]]/}"
      [[ -z "$tool" ]] && continue
      # torch pulled separately with the right index (CPU build by default,
      # ROCm in layer_H_ai_ml_local).
      if [[ "$tool" == "torch" ]]; then
        sub "uv tool install torch (CPU build)"
        run uv tool install torch --index-url https://download.pytorch.org/whl/cpu || \
          warn "torch CPU install failed; retrying without index"
        continue
      fi
      sub "uv tool install $tool"
      run uv tool install "$tool" || warn "uv tool install $tool failed (continuing)"
    done < "$stack"
  fi

  # Smoke test (best-effort)
  if [[ "$DRY_RUN" == 0 ]]; then
    command -v uv     >/dev/null && uv --version    | sed 's/^/   uv: /'
    command -v ruff   >/dev/null && ruff --version  | sed 's/^/   ruff: /'
    command -v mypy   >/dev/null && mypy --version  | sed 's/^/   mypy: /'
    command -v manim  >/dev/null && manim --version | sed 's/^/   manim: /' || true
  fi
}

# --------------------------------------------------------------------------- #
# LAYER C · Data tier (L4) — PG17, Valkey, Qdrant, Meili, ClickHouse, DuckDB  #
# Container-first via podman-compose; clients on host via pacman/AUR.         #
# --------------------------------------------------------------------------- #
layer_C_data_tier() {
  log "Layer C — Data tier"
  run pac duckdb pgcli                          # always-on host CLIs
  run aur litestream-bin sqlx-cli atlas 2>/dev/null || true
  # cargo-installed where AUR lags:
  command -v sqlx >/dev/null 2>&1 || run cargo install sqlx-cli --no-default-features --features postgres
  command -v atlas >/dev/null 2>&1 || run go install ariga.io/atlas/cmd/atlas@latest || true

  # Compose secrets (passwords) — generate if missing.
  local pg_pw="$HOME/.config/postgres/dev.password"
  if [[ ! -f "$pg_pw" ]]; then
    run mkdir -p "$(dirname "$pg_pw")"
    if [[ "$DRY_RUN" == 0 ]]; then
      umask 077; openssl rand -base64 24 > "$pg_pw"
    fi
    sub "wrote $pg_pw"
  fi
  local gf_pw="$HOME/.config/grafana-provisioning/admin.password"
  if [[ ! -f "$gf_pw" ]]; then
    run mkdir -p "$(dirname "$gf_pw")"
    if [[ "$DRY_RUN" == 0 ]]; then
      umask 077; openssl rand -base64 24 > "$gf_pw"
    fi
    sub "wrote $gf_pw"
  fi

  # Bring up the data profile only (obs comes in layer D).
  run podman compose -f "$COMPOSE/dev-stack.yaml" --profile data up -d

  # The observability tier (Loki/Tempo/OTel/ClickHouse) is NO LONGER boot-enabled —
  # login stays lean. It comes up on demand when you open the monitoring cockpit
  # (workspaces.toml [workspaces.monitoring].services = ["dev-stack-obs"], via `cockpit
  # monitoring` / Mod+5). The data tier is likewise staged by the coding/engine scene.
  # Remove ONLY the autostart symlink — NOT `systemctl disable`, which would also delete
  # the stow-provided unit symlink and leave the unit un-findable for on-demand `start`.
  # The stow'd unit stays `linked` = available but not autostarted. Idempotent.
  run rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/default.target.wants/dev-stack-obs.service"
  run systemctl --user daemon-reload
}

# --------------------------------------------------------------------------- #
# LAYER D · Observability tier (L5) — Vector/Prom/Grafana/Loki/Tempo/OTel     #
# --------------------------------------------------------------------------- #
layer_D_observability() {
  log "Layer D — Observability tier"
  run pac grafana prometheus vector
  run aur loki-bin tempo-bin opentelemetry-collector-bin parca-bin 2>/dev/null || true

  # Provisioning configs live under ~/.config/grafana-provisioning (stowed).
  # Grafana + Prometheus are HOST pacman installs (NOT containers); loki/tempo/
  # otel run in dev-stack bound to 127.0.0.1, so datasource URLs use localhost.
  run mkdir -p "$HOME/.config/grafana-provisioning/datasources" \
               "$HOME/.config/grafana-provisioning/dashboards" \
               "$HOME/.config/prometheus" \
               "$HOME/.config/loki" \
               "$HOME/.config/tempo" \
               "$HOME/.config/otel" \
               "$HOME/.config/vector"

  # Wire grafana datasource provisioning into grafana's REAL dir (host install)
  # + restart. URLs target localhost (host prometheus + 127.0.0.1 loki/tempo).
  run sudo install -D -m644 "$HOME/.config/grafana-provisioning/datasources/datasources.yml" \
        /etc/grafana/provisioning/datasources/slicedlabs.yml
  run sudo systemctl restart grafana

  # Vector ships journald -> Loki. Install the dotfiles config + a drop-in that
  # pins vector to it (ignoring the packaged demo vector.yaml) + journal access.
  run sudo install -D -m644 "$HOME/.config/vector/vector.toml" /etc/vector/vector.toml
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/vector.service.d/10-config.conf" \
        /etc/systemd/system/vector.service.d/10-config.conf
  run sudo usermod -aG systemd-journal vector
  run sudo systemctl daemon-reload
  # vector is ON-DEMAND per the boot contract (Layer S disables boot-enable); start it
  # with `monitoring-backends up` for a manual Grafana dive. Config is installed above.

  # eBPF continuous profiling: grafana-alloy's pyroscope.ebpf -> local Pyroscope
  # (pkgs grafana-alloy + pyroscope-bin; services in system/services.txt). Alloy
  # runs as the unprivileged grafana-alloy user, so grant the least-privilege
  # caps it needs + allow CAP_SYSLOG to read kallsyms (kptr_restrict 2->1). The
  # relabel in the .alloy names profiles by exe basename (not "unspecified").
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/grafana-alloy/pyroscope-ebpf.alloy" \
        /etc/grafana-alloy/pyroscope-ebpf.alloy
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/grafana-alloy.service.d/10-ebpf-caps.conf" \
        /etc/systemd/system/grafana-alloy.service.d/10-ebpf-caps.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/sysctl.d/90-pyroscope-ebpf.conf" \
        /etc/sysctl.d/90-pyroscope-ebpf.conf
  run sudo sysctl --system >/dev/null
  run sudo systemctl daemon-reload
  run sudo systemctl restart grafana-alloy.service 2>/dev/null || true

  # Bring up the obs profile.
  run podman compose -f "$COMPOSE/dev-stack.yaml" --profile obs up -d
}

# --------------------------------------------------------------------------- #
# LAYER S · System hardening — scheduler·OOM·indexer·network·firewall + boot   #
# contract (reversible drop-ins, all tracked under system/etc/)                #
# --------------------------------------------------------------------------- #
layer_S_system_hardening() {
  log "Layer S — system hardening (scheduler · OOM · indexer · network · firewall · boot contract)"

  # Boot perf: cap the network-online wait (--any --timeout=5) + soften vector's
  # hard net dep, so neither sits on the boot critical-chain (was a ~10.6s DHCP
  # block on enp0s31f6). Reversible drop-ins; wait-online is NOT masked (wg/tailscale
  # may still gate on it). See system/etc/systemd/system/*.service.d/.
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/systemd-networkd-wait-online.service.d/10-fast.conf" \
        /etc/systemd/system/systemd-networkd-wait-online.service.d/10-fast.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/vector.service.d/20-no-net-block.conf" \
        /etc/systemd/system/vector.service.d/20-no-net-block.conf

  # Firewall: default-drop nftables (trusts lo + tailscale0 + WireGuard). Tracked SSOT
  # in system/etc/nftables.conf; syntax-gated before it can load.
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/nftables.conf" /etc/nftables.conf
  run sudo nft -c -f /etc/nftables.conf
  run sudo systemctl daemon-reload
  run sudo systemctl enable --now nftables.service

  # --- Scheduler: scx_lavd, config-driven via /etc/default/scx (SSOT). Replaced
  # scx_rusty, which crash-looped on this linux-cachyos-bore kernel (10-14s
  # "runnable task stall" freezes + libbpf version skew). Fallback to in-kernel
  # BORE: `sudo systemctl disable --now scx.service`.
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/default/scx" /etc/default/scx
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/scx.service" /etc/systemd/system/scx.service

  # --- networkd: ethernet RequiredFamilyForOnline=ipv4 (don't block boot waiting
  # on IPv6 to settle) + the 10-fast.conf cap raised to 20s. The old 5s cap was
  # shorter than the ~10.6s DHCP, so wait-online FAILED every boot and marked the
  # system `degraded` (the orange [FAILED]). wlan/wwan are already =no.
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/network/20-ethernet.network" /etc/systemd/network/20-ethernet.network
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/network/20-wlan.network" /etc/systemd/network/20-wlan.network
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/network/20-wwan.network" /etc/systemd/network/20-wwan.network

  # --- OOM resilience: systemd-oomd kills the hog under pressure BEFORE the
  # kernel OOM-killer takes out the compositor (it had killed a ghostty cockpit).
  # session.slice is marked ManagedOOMPreference=avoid (stowed via systemd-user).
  # zram bumped 4G -> ~15G (zstd) + zram-tuned swappiness. Mirrors Fedora defaults.
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/oomd.conf.d/10-sliced.conf" /etc/systemd/oomd.conf.d/10-sliced.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/-.slice.d/10-oomd.conf" /etc/systemd/system/-.slice.d/10-oomd.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/system/user@.service.d/10-oomd.conf" /etc/systemd/system/user@.service.d/10-oomd.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
  run sudo install -D -m644 "$DOTFILES_ROOT/system/etc/sysctl.d/99-zram-swappiness.conf" /etc/sysctl.d/99-zram-swappiness.conf
  run sudo systemctl enable systemd-oomd.service

  # --- Indexer: disable GNOME localsearch/tracker recursive $HOME indexing (it
  # pegged a core with throttle 0). Nautilus is KEPT — only the miner is off.
  # gsettings empty the index scope + mask the miners; the Hidden XDG autostart
  # override ships in the `autostart` stow package.
  if command -v gsettings >/dev/null 2>&1; then
    run gsettings set org.freedesktop.Tracker3.Miner.Files index-recursive-directories "[]" || true
    run gsettings set org.freedesktop.Tracker3.Miner.Files index-single-directories "[]"   || true
    run gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors false            || true
  fi
  run systemctl --user mask localsearch-3.service localsearch-control-3.service localsearch-writeback-3.service 2>/dev/null || true

  run sudo systemctl daemon-reload
  run systemctl --user daemon-reload

  # Boot contract: observability is on-demand (native `slicedlabs monitor` TUI +
  # `monitoring-backends` helper); printing + battery are absent on this workstation.
  # Disable (never mask) so on-demand start still works. Idempotent on a clean install.
  run sudo systemctl disable grafana.service grafana-alloy.service prometheus.service \
        prometheus-node-exporter.service pyroscope.service vector.service \
        cups.service cups.socket cups.path upower.service 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
# LAYER E · Container + local orchestration (L6) — k3d, kubectl, helm         #
# --------------------------------------------------------------------------- #
layer_E_container_orch() {
  log "Layer E — Container + local orchestration"
  run pac podman-compose podman-docker
  run aur k3d-bin kubectl helm kustomize skaffold-bin kubectx stern-bin k9s zot-bin dive 2>/dev/null || true

  # k3d cluster brought up on demand via bin/dev-k3d-up; not auto-started.
  sub "Run \`dev-k3d-up\` to create the local cluster."
}

# --------------------------------------------------------------------------- #
# LAYER F · Networking / API / Cloud (L7)                                     #
# --------------------------------------------------------------------------- #
layer_F_networking_api() {
  log "Layer F — Networking / API / Cloud"
  run pac tailscale wireguard-tools caddy aria2 httpie
  run aur xh oha vegeta-bin bruno-bin hurl-bin cloudflared-bin flyctl-bin 2>/dev/null || true

  # Tailscale daemon — login is interactive and stays manual.
  run sudo systemctl enable --now tailscaled
  sub "Run \`sudo tailscale up --ssh --accept-routes\` to join the tailnet."
}

# --------------------------------------------------------------------------- #
# LAYER G · Frontend / Web (L8)                                               #
# --------------------------------------------------------------------------- #
layer_G_frontend_web() {
  log "Layer G — Frontend / Web"
  eval "$(mise activate bash)"
  if command -v bun >/dev/null 2>&1; then
    run bun add -g @biomejs/biome vite @playwright/test wrangler @mermaid-js/mermaid-cli
  else
    warn "bun not on PATH — make sure layer_B ran and mise reshim succeeded"
  fi
  run aur playwright-chromium playwright-firefox 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
# LAYER H · AI/ML local (L9) — Vulkan primary, ROCm fallback                  #
# --------------------------------------------------------------------------- #
layer_H_ai_ml_local() {
  log "Layer H — AI/ML local (Vulkan primary, ROCm fallback)"

  # H.1 — Vulkan stack
  run pac vulkan-radeon vulkan-tools vulkan-headers vulkan-icd-loader \
          glslang spirv-tools shaderc

  # H.2 — ROCm fallback (heavy; installed but not on primary path)
  run aur rocm-hip-sdk rocm-opencl-sdk rocm-ml-libraries rocm-smi-lib rocminfo \
          amdgpu_top 2>/dev/null || warn "ROCm AUR install failed — Polaris path may need community-patched builds"

  # GPU device access (idempotent)
  run sudo gpasswd -a "$USER" render || true
  run sudo gpasswd -a "$USER" video  || true

  # Ollama (Vulkan-preferred, ROCm fallback)
  run aur ollama-vulkan 2>/dev/null || run aur ollama
  run aur ollama-rocm 2>/dev/null   || true

  # llama.cpp dual-backend build (Vulkan + HIP)
  if [[ -x "$HOME/.dotfiles/bin/.local/bin/build-llamacpp" ]]; then
    # Sentinel-guarded — a full llama.cpp dual-backend build is expensive; don't
    # rebuild on every bootstrap run (delete ~/.cache/bootstrap/llamacpp_build.done to force).
    sentinel llamacpp_build run "$HOME/.dotfiles/bin/.local/bin/build-llamacpp"
  else
    warn "build-llamacpp script missing — skipping llama.cpp build"
  fi

  # Aider via uv tool install (already in python-stack.txt; explicit here)
  command -v aider >/dev/null 2>&1 || run uv tool install aider-chat

  # Systemd-user units (Vulkan default, ROCm disabled by default).
  run systemctl --user daemon-reload
  # ollama is staged by the `coding` scene (workspaces.toml services), not at boot.

  # Model pulls (deferred — heavy, ~10 GB)
  sub "Run \`pull-llm-models\` to fetch qwen2.5-coder / llama3.2 / nomic-embed / bge-reranker."
}

# --------------------------------------------------------------------------- #
# LAYER I · Security / SBOM + Productivity TUI (L10/L11)                      #
# --------------------------------------------------------------------------- #
layer_I_security_tui() {
  log "Layer I — Security / SBOM + Productivity TUI"
  run pac tmux dust procs bottom sd lazygit glow atuin fastfetch chafa
  run aur lazydocker gh-dash slides presenterm taskwarrior-bin timewarrior-bin \
          semgrep trivy syft-bin cosign grype-bin trufflehog-bin 2>/dev/null || true

  command -v cargo-vet     >/dev/null 2>&1 || run cargo install cargo-vet
  command -v cargo-machete >/dev/null 2>&1 || run cargo install cargo-machete

  # Runtime security: Cilium Tetragon (eBPF). The AUR `tetragon-bin` is a wrong/
  # joke binary, so install from the official release (out-of-band, like the
  # llama.cpp/osxcross builds) + load the tracked TracingPolicies. cargo-audit +
  # cargo-deny (layer 4) are wired into the pre-push hook, not re-installed here.
  run "$DOTFILES_ROOT/bin/.local/bin/install-tetragon" 2>/dev/null \
      || warn "tetragon install skipped (network?) — run install-tetragon by hand"
}

# --------------------------------------------------------------------------- #
# LAYER J · Pomodoro + Niri + Waybar (L12/L13)                                #
# --------------------------------------------------------------------------- #
layer_J_pomodoro_niri_waybar() {
  log "Layer J — Pomodoro + Niri + Waybar"
  run aur uair-git zen-browser-bin excalidraw-desktop-bin d2-bin 2>/dev/null || true

  # Regenerate the Waybar GENERATED regions from tabs.toml FIRST, then re-render
  # all templates — render-waybar must precede render-templates (the latter
  # resolves the {{tokens}} the former emits). Without this, a fresh host with
  # tabs.toml changes ships stale GENERATED regions.
  run "$DOTFILES_ROOT/bin/.local/bin/render-waybar"
  run "$DOTFILES_ROOT/bin/.local/bin/render-templates"

  # tide prompt — the powerline-capsule prompt (Track 9.1), a fisher plugin pinned in
  # fish_plugins. `fisher update` is idempotent; bootstraps fisher if absent.
  if command -v fish >/dev/null 2>&1; then
    fish -c 'functions -q fisher && fisher update' >/dev/null 2>&1 \
      || fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; and fisher update' >/dev/null 2>&1 \
      || warn "fisher/tide update skipped (network?) — run 'fisher update' by hand"
  fi
  # zjstatus — the Liquid-Glass pill tab/status bar plugin for zellij. Fetch the wasm
  # if absent (the layouts reference it via the `zjstatus` alias in config.kdl).
  zjs="$HOME/.config/zellij/plugins/zjstatus.wasm"
  if [[ ! -f "$zjs" ]]; then
    install -d "$HOME/.config/zellij/plugins"
    curl -sL -o "$zjs" \
      "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" 2>/dev/null \
      || warn "zjstatus.wasm fetch skipped (network?) — the zellij bar is blank until present"
  fi
  # zjstatus is a third-party plugin → zellij requires a permission grant. SEED it
  # idempotently in the exact format zellij itself writes (~/.cache/zellij/permissions.kdl),
  # so a fresh install needs no manual step. `zj grant` (open full-pane, press y) remains
  # the interactive fallback if the cache is ever cleared.
  perm="$HOME/.cache/zellij/permissions.kdl"
  if [[ -f "$zjs" ]] && ! grep -qF "zjstatus.wasm" "$perm" 2>/dev/null; then
    install -d "$(dirname "$perm")"
    printf '"%s" {\n    ReadApplicationState\n    ChangeApplicationState\n    RunCommands\n}\n' \
      "$zjs" >> "$perm"
    log "zjstatus: permission seeded (pill bar enabled, no manual grant needed)"
  fi

  # btop is now FULLY MANAGED (Track 9): the tracked btop.conf sets save_config_on_exit
  # = false, so btop never rewrites it — which is what previously forced the seed-only
  # workaround (a symlinked tracked config would get clobbered + pollute the source).
  # Now both the token-driven theme AND the config symlink straight from the dotfiles.
  if command -v btop >/dev/null 2>&1; then
    install -d "$HOME/.config/btop/themes"
    ln -sf "$DOTFILES_ROOT/btop/.config/btop/themes/slicedlabs.theme" \
           "$HOME/.config/btop/themes/slicedlabs.theme"
    ln -sf "$DOTFILES_ROOT/btop/.config/btop/btop.conf" \
           "$HOME/.config/btop/btop.conf"
  fi

  # uair daemon — staged by the engine/coding scenes (workspaces.toml services), not at boot.
  run systemctl --user daemon-reload

  # Force waybar refresh so the new tab modules appear.
  pkill -SIGRTMIN+8 waybar 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
# LAYER K · Book recommendations (no install — files only)                    #
# --------------------------------------------------------------------------- #
layer_K_books() {
  log "Layer K — Book recommendations"
  local target="$DOTFILES_ROOT/docs/book-recommendations-2026.md"
  if [[ -f "$target" ]]; then
    sub "$target already present"
  else
    warn "missing $target — write it before re-running this layer"
  fi
}

# =========================================================================== #
# EXTENSION · Personal AI Team + Knowledge System (L → R)                     #
# =========================================================================== #

# --------------------------------------------------------------------------- #
# LAYER L · Knowledge ingestion (books + code + notes)                        #
# --------------------------------------------------------------------------- #
layer_L_knowledge_ingestion() {
  log "Layer L — Knowledge ingestion"
  command -v marker      >/dev/null 2>&1 || run uv tool install marker-pdf
  command -v watchexec   >/dev/null 2>&1 || run pac watchexec
  # slicedlabs-team (this dotfile-tracked Python package) provides the
  # ingest/search modules; install editable so source-of-truth lives here.
  if [[ -d "$DOTFILES_ROOT/slicedlabs-team" ]]; then
    run uv pip install --system -e "$DOTFILES_ROOT/slicedlabs-team[tui]" 2>/dev/null || \
      run uv tool install -e "$DOTFILES_ROOT/slicedlabs-team[tui]" 2>/dev/null || \
      warn "slicedlabs-team editable install failed; run \`uv pip install --system -e ~/.dotfiles/slicedlabs-team[tui]\` manually"
  fi
  sub "Run \`ingest-books\` to bulk-ingest ~/Resources/books/ (1-2 hours)."
}

# --------------------------------------------------------------------------- #
# LAYER M · Long-term memory (Mem0 self-hosted)                               #
# --------------------------------------------------------------------------- #
layer_M_long_term_memory() {
  log "Layer M — Long-term memory (Mem0)"
  # Compose secrets — Neo4j auth (auto-generated if missing).
  local neo4j_auth="$HOME/.config/neo4j/auth"
  if [[ ! -f "$neo4j_auth" ]]; then
    run mkdir -p "$(dirname "$neo4j_auth")"
    if [[ "$DRY_RUN" == 0 ]]; then
      # hex (not base64) — Neo4j parses NEO4J_AUTH as user/password and any
      # '/' in the password breaks the parse, so avoid base64 here.
      umask 077; printf 'neo4j/%s\n' "$(openssl rand -hex 24)" > "$neo4j_auth"
    fi
    sub "wrote $neo4j_auth"
  fi
  run podman compose -f "$COMPOSE/ai-stack.yaml" --profile memory up -d
  # ai-stack is staged by the `coding` scene (workspaces.toml services), not at boot.
}

# --------------------------------------------------------------------------- #
# LAYER N · Agent observability + safety (Langfuse + Phoenix)                 #
# --------------------------------------------------------------------------- #
layer_N_agent_observability() {
  log "Layer N — Agent observability"
  # Langfuse session secrets
  for f in nextauth_secret salt; do
    local p="$HOME/.config/langfuse/$f"
    if [[ ! -f "$p" ]]; then
      run mkdir -p "$(dirname "$p")"
      if [[ "$DRY_RUN" == 0 ]]; then
        umask 077; openssl rand -base64 32 > "$p"
      fi
    fi
  done
  run podman compose -f "$COMPOSE/ai-stack.yaml" --profile obs up -d
}

# --------------------------------------------------------------------------- #
# LAYER O · SlicedLabs Agent Team (13 named roles)                            #
# --------------------------------------------------------------------------- #
layer_O_agent_team() {
  log "Layer O — SlicedLabs Agent Team (13 roles)"
  # The agent .md files are stowed via the claude-agents package; the
  # Python orchestrator (CrewAI) is installed by layer_L's slicedlabs-team
  # editable install. Verify the bin/slicedlabs CLI is on PATH.
  command -v slicedlabs >/dev/null 2>&1 || \
    warn "slicedlabs CLI not on PATH — make sure ~/.dotfiles/bin/.local/bin is stowed"
  sub "Try \`slicedlabs ask slicedlabs_architect 'hello'\`"
}

# --------------------------------------------------------------------------- #
# LAYER P · Automation, scheduling, Pomodoro integration                      #
# --------------------------------------------------------------------------- #
layer_P_automation() {
  log "Layer P — Automation (n8n + Pomodoro hooks + Discord)"
  run podman compose -f "$COMPOSE/ai-stack.yaml" --profile auto up -d
  sub "n8n UI: http://localhost:5678 — import workflows from ~/.config/n8n/workflows/"
}

# --------------------------------------------------------------------------- #
# LAYER Q · Visualization & knowledge graphs (Obsidian + Cognee + D2)         #
# --------------------------------------------------------------------------- #
layer_Q_visualization() {
  log "Layer Q — Visualization & knowledge graphs"
  run aur obsidian-bin excalidraw-desktop-bin d2-bin 2>/dev/null || true
  run pac graphviz
  run podman compose -f "$COMPOSE/ai-stack.yaml" --profile kg up -d 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
# LAYER R · Context engineering & prompt CI                                   #
# --------------------------------------------------------------------------- #
layer_R_context_engineering() {
  log "Layer R — Context engineering & prompt CI"
  command -v jinja2 >/dev/null 2>&1 || run uv tool install jinja2-cli
  # The prompt-ci pre-commit hook is installed via install-hooks.
  if [[ -x "$DOTFILES_ROOT/bin/.local/bin/install-hooks" ]]; then
    run "$DOTFILES_ROOT/bin/.local/bin/install-hooks"
  fi
  sub "Renders .claude/agents/*.md from prompts/roles/*.md on commit."
}

# --------------------------------------------------------------------------- #
# LAYER V · virtualization (rootless libvirt/KVM — the coding command center)  #
# --------------------------------------------------------------------------- #
layer_V_virtualization() {
  log "Layer V — Virtualization (rootless libvirt/KVM · OVMF/swtpm · virtiofs · SPICE)"
  # qemu-base, edk2-ovmf, virtiofsd, passt are already on the box (baseline); add libvirt,
  # the desktop managers, the software-TPM, and qemu's SPICE display modules.
  pac libvirt virt-manager virt-viewer swtpm spice-gtk qemu-ui-spice-core qemu-ui-spice-app
  # /dev/kvm is already world-usable (0666); add the group too for correctness.
  run sudo usermod -aG kvm "$USER" || true
  # ROOTLESS session libvirt: the per-user daemon (virtqemud) is auto-exec'd by the libvirt
  # client on first connect — no system service at boot, no libvirt group, no relogin needed.
  export LIBVIRT_DEFAULT_URI=qemu:///session   # also set for shells in fish conf.d/virt.fish
  # Establish the baseline domains (idempotent; DEFINES only — never boots a guest here).
  if command -v vm >/dev/null 2>&1; then
    run vm ensure || warn "vm ensure deferred — re-run \`vm ensure\` after the install settles"
  else
    warn "vm not on PATH yet (stow bin/) — run \`vm ensure\` once it is"
  fi
  sub "Summon the VM console on coding with \`coding-vm\` / Mod+Ctrl+Shift+V. \`vm --help\` for all."
}

# --------------------------------------------------------------------------- #
# LAYER W · atomic rollback + agent capability sandbox (spec P11)              #
# --------------------------------------------------------------------------- #
layer_W_atomic_sandbox() {
  log "Layer W — Atomic rollback (snapper/snap-pac) + agent capability sandbox (P11)"
  # ATOMIC: rootfs is btrfs with snapper configs (root + home). snap-pac adds the
  # pre/post pacman hooks → every `pacman -S/-U/-R` is bracketed by a snapshot, so any
  # system transaction is atomically rollback-able (snapper undochange / rollback).
  pac snap-pac
  sub "atomic: snap-pac brackets every pacman transaction with a btrfs snapshot"
  # CAPABILITY SANDBOX: the sl-agents.slice cgroup (stowed systemd-user unit) caps
  # autonomous-agent CPU/mem. Pick it up now; `slc-claude --as <role>` + `sl-sandbox` use it.
  run systemctl --user daemon-reload
  sub "sandbox: sl-agents.slice — autonomous agents CPU/mem-capped (sl-sandbox <cmd>)"
  # SECURE BOOT (P10): sbctl signs the bootloader + UKIs with local keys. Signing is INERT
  # while SB is off (boot unchanged); `secureboot setup` does it. Activating SB (enroll +
  # a firmware toggle) is the operator's deliberate, brick-aware step — never automated.
  pac sbctl
  sub "secure-boot: \`secureboot setup\` signs bootloader+UKIs; enable knowingly (RUNBOOK-platform)"
  # UKI boot (systemd-boot + mkinitcpio UKI presets) is already in place — verify only.
  command -v verify-platform >/dev/null 2>&1 && run verify-platform || true
}

# =========================================================================== #
# Dispatcher                                                                  #
# =========================================================================== #
LAYER_ORDER=(0 1 2 3 4 5 6 7 8 B C E D S V W F G I H J K L M N R O Q P)

resolve_layer() {
  # Map "B" → "layer_B_python_ecosystem" by scanning declared functions.
  local id="$1"
  declare -F | awk '{print $3}' | grep -E "^layer_${id}_" | head -1
}

list_layers() {
  printf 'Layers (recommended execution order):\n'
  local fn
  for id in "${LAYER_ORDER[@]}"; do
    fn=$(resolve_layer "$id")
    printf '  %-2s  %s\n' "$id" "${fn:-<missing>}"
  done
}

run_layer() {
  local fn
  fn=$(resolve_layer "$1") || true
  if [[ -z "$fn" ]]; then err "no layer matching '$1'"; return 1; fi
  "$fn"
}

main() {
  local ARGS=("$@")
  local SKIP=()
  local FROM=""
  local ONLY=()

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --list)    list_layers; return 0 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --layer)   shift; while [[ "$#" -gt 0 && "$1" != --* ]]; do ONLY+=("$1"); shift; done ;;
      --skip)    shift; while [[ "$#" -gt 0 && "$1" != --* ]]; do SKIP+=("$1"); shift; done ;;
      --from)    shift; FROM="$1"; shift ;;
      *)         err "unknown arg: $1"; exit 2 ;;
    esac
  done

  if [[ "${#ONLY[@]}" -gt 0 ]]; then
    for id in "${ONLY[@]}"; do run_layer "$id"; done
    return 0
  fi

  local started=1
  if [[ -n "$FROM" ]]; then started=0; fi

  for id in "${LAYER_ORDER[@]}"; do
    if [[ "$started" == 0 && "$id" == "$FROM" ]]; then started=1; fi
    if [[ "$started" == 0 ]]; then continue; fi
    for s in "${SKIP[@]:-}"; do [[ "$id" == "$s" ]] && continue 2; done
    run_layer "$id" || { err "layer $id failed — re-run with --from $id once fixed"; exit 1; }
  done

  log "bootstrap complete"
  if [[ "$DRY_RUN" == 0 && -x "$DOTFILES_ROOT/bin/.local/bin/snapshot-packages" ]]; then
    sub "refreshing package snapshot…"
    "$DOTFILES_ROOT/bin/.local/bin/snapshot-packages" || true
  fi
}

main "$@"
