# 2026 Polyglot Stack — Runbook

The full plan lives in `~/.claude/plans/abundant-prancing-rabbit.md`. This
runbook is the operator-facing distillation: **what to run, in what order,
and what to verify** once each layer lands.

## Phase summary

| Phase | Layer | What it adds |
|---|---|---|
| A | (scaffolding) | tokens, mise pins, compose stubs, layer functions |
| 0–8 | baseline | unchanged from before — see `bootstrap.sh` |
| B | L2/L3 | Python ecosystem via uv (ruff, manim, torch, langchain, …) |
| C | L4 | PG17 + Valkey + Qdrant + Meili + ClickHouse + DuckDB |
| D | L5 | Vector + Prom + Grafana + Loki + Tempo + OTel collector |
| E | L6 | k3d + kubectl + helm + kustomize + zot |
| F | L7 | Tailscale + Caddy + xh + Bruno + Hurl + Fly |
| G | L8 | Bun + Deno + Biome + Vite + Playwright |
| H | L9 | Vulkan-primary AI (Ollama + llama.cpp + Aider + Continue) |
| I | L10/L11 | Security/SBOM + Productivity TUI (atuin, lazygit, btm) |
| J | L12/L13 | uair Pomodoro + Niri coding/browser + Waybar tabs/workstation |
| K | — | `docs/book-recommendations-2026.md` |
| L | extension | Marker → Qdrant book/code/notes ingest |
| M | extension | Mem0 long-term memory (PG + Qdrant + Neo4j) |
| N | extension | Langfuse + Phoenix + cost caps + audit log |
| O | extension | 13-role SlicedLabs agent team |
| P | extension | n8n automation + Pomodoro hooks + Discord routines |
| Q | extension | Obsidian + Cognee + D2 + Mermaid + Excalidraw |
| R | extension | Prompt CI + brand voice + golden evals |

## Run order (one-shot from a fresh dotfiles clone)

```bash
cd ~/.dotfiles

# 1. Render templates (tokens.toml → niri/waybar/etc. outputs).
bin/.local/bin/render-templates

# 2. Stow every package. New packages added by this plan:
stow podman-compose grafana-provisioning prometheus loki tempo otel vector \
     mem0 langfuse n8n cognee claude-hooks claude-agents \
     ai postgres aider continue obsidian uair sliced-engine slicedlabs-team \
     fish

# 3. Run the layered installer (warnings are OK; errors → re-run with --from <id>).
./bootstrap.sh

# 4. Pull AI models (deferred — ~10 GB).
pull-llm-models

# 5. Ingest the corpus (deferred — 1–2 hours).
ingest-books
ingest-code
ingest-notes

# 6. Wire Claude Code hooks (merge claude-hooks/.claude/hooks/settings.json.sample
#    into ~/.claude/settings.json).

# 7. Open Mod+D — coding workspace activates. ghostty+zellij opens in ~/Projects/engine.
#    Open Mod+B — browser workspace activates. Zen opens.
```

## Layer-by-layer verification

### After Phase A (scaffolding)
```bash
./bootstrap.sh --list                                 # 26 layers visible
render-templates                                      # all templates resolve
```

### After Phase B (Python)
```bash
uv --version && ruff --version && mypy --version
python -c "import torch, transformers, langchain, manim, polars; print('ok')"
```

### After Phase C (data tier)
```bash
systemctl --user is-active dev-stack.service
psql -h localhost -U dev -c '\l'
valkey-cli ping
curl localhost:6333/healthz
curl localhost:7700/health
curl localhost:8123/ping
duckdb -c 'select version()'
```

### After Phase D (observability)
```bash
curl localhost:3000/api/health     # grafana
curl localhost:9090/-/healthy      # prometheus
curl localhost:3100/ready          # loki
curl localhost:4318/v1/traces -X POST -d '{}'    # otel
vector validate ~/.config/vector/vector.toml
```

### After Phase E (orchestration)
```bash
dev-k3d-up
k3d cluster list
kubectl get nodes
helm version
```

### After Phase F (networking)
```bash
xh httpbin.org/get | jq .url
tailscale status
```

### After Phase G (frontend)
```bash
bun --version && deno --version && biome --version
bunx playwright --version
```

### After Phase H (AI/ML)
```bash
vulkaninfo --summary | grep -E 'deviceName.*RX 580|RADV POLARIS10'
llama-server --version
ollama list
ollama run qwen2.5-coder:1.5b 'print hello in rust'    # responds via Vulkan
amdgpu_top                                              # confirm GPU active

# ROCm path
with-rocm python -c 'import torch; print(torch.cuda.is_available())'
systemctl --user start ollama-rocm                      # swap backend
```

### After Phase J (Pomodoro + Niri + Waybar)
```bash
uairctl --help && uairctl toggle && uairctl fetch '{name} {time}'
niri msg workspaces | grep -E 'coding|browser'
# Eye-test: Mod+D opens coding workspace; Mod+B opens browser workspace.
# Eye-test: left waybar shows workstation chip aggregating repo+branch+build+pomo.
```

### After Phase L–R (AI team)
```bash
slicedlabs prompts list                                 # 13 roles
slicedlabs ask slicedlabs_architect "hello"             # responds (degraded
                                                        # if ANTHROPIC_API_KEY empty)
slicedlabs ingest --status                              # corpus counts
slicedlabs cost today                                   # spend table
slicedlabs audit --since 1h                             # tool calls
curl localhost:3030/api/health                          # langfuse
curl localhost:5678                                     # n8n
curl localhost:8089/health                              # mem0
```

## Common breakage and recovery

- **podman compose says "network exists"** — run `podman network ls` and
  `podman network rm devnet` (the ai-stack expects to *join* devnet).
- **render-templates fails** — usually a stray `{{section.key}}` in a
  template — run `render-templates --check` to see the offending tokens.
- **ROCm doesn't see gfx803** — confirm `HSA_OVERRIDE_GFX_VERSION=8.0.3`
  is set; rerun with `with-rocm`. If still failing, fall back to Vulkan
  (it's the default — no action needed).
- **uair.service won't start** — `journalctl --user -u uair.service -n 30`.
  Most often: `/usr/bin/uair` not on PATH; reinstall `uair-git`.
- **`bunx playwright` says "no browsers"** — `bunx playwright install`.

## Cost guardrails (Phase N)

- Default per-task hard cap: **$1**
- Default daily soft cap: **$25** — soft warning to Discord `#alarms`
- Default daily hard cap: **$50** — every agent except `slicedlabs_accountant`
  pauses; resume with `slicedlabs resume`

Override via env in `~/.dotfiles/fish/.config/fish/conf.d/ai.fish` (or per
session in a shell).

## API key setup (deferred — works without)

`~/.config/ai/keys.env.sops` ships as empty placeholders. To activate the
cloud LLMs:

```fish
sops ~/.dotfiles/ai/.config/ai/keys.env.sops
# add ANTHROPIC_API_KEY="..." and OPENAI_API_KEY="..."

render-secrets    # decrypts to ~/.config/ai/keys.env
```

Until then, Aider, Continue, and the agent team run in **local-Ollama-only**
mode — every command still works, just at a lower model tier.
