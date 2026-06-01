#!/usr/bin/env bash
# corpus.sh — coding tab "knowledge corpus health" chip. Reads chunk counts
# from Qdrant + last ingest age from a cache file.

set -eu

tab_id="coding"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

cache="${XDG_CACHE_HOME:-$HOME/.cache}/slicedlabs-corpus.json"
if [[ ! -f "$cache" ]]; then
  printf '{"text":"corpus: ?","class":"info","tooltip":"run ingest-books to populate"}\n'
  exit 0
fi

chunks=$(jq -r '.chunks // 0'         < "$cache" 2>/dev/null || echo 0)
last=$(  jq -r '.last_ingest_ts // 0' < "$cache" 2>/dev/null || echo 0)
age=$(( $(date +%s) - last ))
days=$(( age / 86400 ))

class="info"
[[ "$days" -gt 7 ]] && class="warning"
[[ "$days" -gt 30 ]] && class="critical"

printf '{"text":" %s · %dd","class":"%s","tooltip":"chunks: %s\\nlast ingest: %d days ago\\nclick: slicedlabs ingest --status"}\n' \
  "$chunks" "$days" "$class" "$chunks" "$days"
