#!/usr/bin/env bash
# tests.sh — [ENGINE] test footprint chip.
#
# Two-source design:
#   (a) If $XDG_CACHE_HOME/engine-tests.json exists (written by a post-test
#       hook or `cargo watch` runner), parse {passed,failed,timestamp} and
#       render PASS/FAIL counts.
#   (b) Otherwise, count `#[test]` annotations across $ENGINE_REPO/crates/**
#       as a "tests defined" indicator. Cached 60s on disk.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "engine" ]] || { echo ""; exit 0; }

REPO="${ENGINE_REPO:-$HOME/Projects/engine}"
RESULT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/engine-tests.json"
COUNT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/engine-tests-count"
TTL=60

if [[ -f "$RESULT_CACHE" ]]; then
    passed=$(jq -r '.passed // 0' "$RESULT_CACHE" 2>/dev/null || echo 0)
    failed=$(jq -r '.failed // 0' "$RESULT_CACHE" 2>/dev/null || echo 0)
    if (( failed > 0 )); then
        printf '{"text":"✗ %d failed / %d","class":"critical","tooltip":"engine-tests.json — fix tests"}\n' "$failed" "$((passed+failed))"
    else
        printf '{"text":"✓ %d/%d","class":"ok","tooltip":"engine-tests.json — all green"}\n' "$passed" "$((passed+failed))"
    fi
    exit 0
fi

# Fallback: count of #[test] annotations.
if [[ ! -d "$REPO/crates" ]]; then
    printf '{"text":"󰙨 · no tests","class":"empty","tooltip":"%s/crates does not exist"}\n' "$REPO"
    exit 0
fi

if [[ ! -f "$COUNT_CACHE" ]] || (( $(date +%s) - $(stat -c %Y "$COUNT_CACHE" 2>/dev/null || echo 0) > TTL )); then
    grep -RoE '#\[(test|tokio::test|async_test)\]' "$REPO/crates" 2>/dev/null | wc -l > "$COUNT_CACHE"
fi
count=$(<"$COUNT_CACHE")
printf '{"text":"󰙨 %d defined","class":"info","tooltip":"#[test] annotations under crates/ (no recent run)"}\n' "$count"
