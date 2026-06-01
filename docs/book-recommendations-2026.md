# 2026 Book Recommendations — SlicedLabs Senior-Engineer Stack

Curated to plug the gaps in `~/Resources/books/` and to align with the polyglot
2026 stack (`bootstrap.sh` layers B–R). One-line "why" per entry. Tier order
within each section is **read-first → reference**.

> Already-owned titles are not repeated here; if you can't find an entry on
> your shelf, it's a gap.

---

## Distributed systems / databases

- **Designing Data-Intensive Applications, 2nd ed.** — Martin Kleppmann
  Canonical reference. Storage, replication, consensus, stream processing —
  the only one-volume book that fully covers the 2026 data tier (PG 17 + Valkey
  + Qdrant + Meili + ClickHouse + DuckDB). _Buy this one even if you skip every
  other entry._

- **Database Internals** — Alex Petrov
  B-tree → LSM → consensus → distributed transactions, in a single arc. Pairs
  perfectly with the layer C data mesh.

- **Patterns of Distributed Systems** — Unmesh Joshi (Martin Fowler signature)
  Pattern catalog: raft, quorum, clock skew, lease-based locking, write-ahead
  logging. Read after DDIA when you need recipes, not theory.

- **The Internals of PostgreSQL** — Hironobu Suzuki (free online)
  Pairs with PostgreSQL 17 in the data tier. Page layout, MVCC, vacuum, query
  planner — the parts you need to debug production issues nobody else can.

---

## Security / cryptography

- **Real-World Cryptography** — David Wong
  Modern crypto (ECC, post-quantum, TLS 1.3, Signal, Noise) without the math
  drag. Aligns with the engine's threat model and sops/age workflow.

- **Practical Cryptography for Developers** — Svetlin Stoyanov (free online)
  Fits the sops + age + cosign workflow you already run. Hands-on.

- **The Tangled Web** — Michal Zalewski
  Still the definitive book on browser/web security models in 2026. Pairs with
  Zen + Playwright work in layer G.

---

## Software design / cognition

- **A Philosophy of Software Design, 3rd ed.** — John Ousterhout
  Module depth, complexity, comments-that-matter. Engine-applicable; cited
  often in `[ENGINE]` design reviews.

- **Tidy First?** — Kent Beck
  Small-refactor discipline. Lowest-cost reading of the year — finish it on a
  weekend, apply it forever.

- **The Programmer's Brain** — Felienne Hermans
  How working memory shapes code clarity. Why your engine naming matters. The
  book your design assistant `slicedlabs_design_assistant` will quote at you.

---

## Formal methods

- **Software Foundations** (Vol 1: Logical Foundations) — Benjamin Pierce et al.
  Free. Coq-based proof of program properties. Read selectively — the first
  six chapters are 90% of the value.

- **Practical TLA+** — Hillel Wayne
  Model-check concurrent engine subsystems before they ship races. TLA+ has
  changed less than your codebase has; this book stays current.

---

## Observability / SRE

- **Observability Engineering** — Charity Majors, Liz Fong-Jones, George Miranda
  Cardinality, structured events, the "three pillars" critique. Pairs with the
  layer D stack (OTel + Tempo + Loki + Vector + Grafana). Required reading
  before you wire `[ENGINE]` to OTLP.

- **Site Reliability Engineering** — Beyer, Jones, Petoff, Murphy et al.
  The classic (free online). Solo-operator read: chapters 1–6, 22, 32.

---

## Rust depth (fills gaps in an already-strong Rust shelf)

- **Rust Atomics and Locks** — Mara Bos
  Exactly what `[ENGINE]` needs for sound multi-threaded ECS. Bos is the maintainer
  of `std::sync` — there is no better source.

- **Zero to Production in Rust** — Luca Pascutto
  Practical async/server patterns. Useful for engine companion services
  (asset CDN, telemetry collector, agent API).

---

## Game engine — fills the visible gaps in `~/Resources/books`

- **Foundations of Game Engine Development, Vol 3 (Animation)** — Eric Lengyel
  You have Vol 1 + Vol 2. This completes the math + rendering + animation arc.

- **Foundations of Game Engine Development, Vol 4 (Physics)** — Eric Lengyel
  Same series, physics. Skip if you outsource physics; otherwise non-optional.

- **Real-Time Shadows** — Eisemann, Schwarz, Assarsson, Wimmer
  Depth your current rendering books skip. PCF → VSM → ESM → CSM → SVOGI.

---

## Linux internals + perf

- **BPF Performance Tools** — Brendan Gregg
  Pairs with your existing **Systems Performance** book and the
  `bpftrace`/`flamegraph` already installed. The one Gregg book to read in 2026
  if you read only one.

---

## On the agent stack (extension phases L–R)

Not a book recommendation — a note. The 2026 AI-agent literature is moving too
fast for print. Track these instead:

- **Anthropic Engineering blog** (`anthropic.com/engineering`) — prompt
  caching, computer use, sub-agents, memory.
- **Mem0 + Langfuse + LlamaIndex changelogs** — the substrate you're building
  on; breaking changes ship monthly in early 2026.
- **Phoenix / Arize Eval Notebook examples** — golden-set patterns that age
  well even when models don't.

---

## Reading order (if starting from zero)

1. _Tidy First?_ — 1 weekend
2. _A Philosophy of Software Design_ — 1 week
3. _Designing Data-Intensive Applications_ — 1 month
4. _Rust Atomics and Locks_ — 1 week
5. _Observability Engineering_ — 1 week
6. _Foundations of Game Engine Development Vol 3 + Vol 4_ — 1 month each

Anything past that is reference; you'll know what you need when the work
demands it.

---

_Last updated 2026-05-28. Edit me when you finish one and want to log the
takeaway. Not tracked in `pass` or sops — public-safe._
