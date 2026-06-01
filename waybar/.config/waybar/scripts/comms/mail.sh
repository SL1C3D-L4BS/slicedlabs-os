#!/usr/bin/env bash
# mail.sh — unread mail count.
#
# Tries (in order): notmuch tag:unread, ~/Mail/**/new, ~/.mail/**/new.
# Falls back to a degraded "· no setup" chip if no mail tooling is present.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "comms" ]] || { echo ""; exit 0; }

if command -v notmuch >/dev/null && notmuch config get database.path >/dev/null 2>&1; then
    count=$(notmuch count tag:unread 2>/dev/null || echo 0)
    if (( count > 0 )); then
        printf '{"text":"󰇮 %d","class":"alert","tooltip":"notmuch: %d unread"}\n' "$count" "$count"
    else
        printf '{"text":"󰇯 0","class":"ok","tooltip":"notmuch: inbox zero"}\n'
    fi
    exit 0
fi

for root in "$HOME/Mail" "$HOME/.mail"; do
    if [[ -d "$root" ]]; then
        count=$(find "$root" -type d -name new -exec sh -c 'ls -1 "$1" | wc -l' _ {} \; 2>/dev/null \
            | awk 'BEGIN{s=0}{s+=$1}END{print s}')
        count="${count:-0}"
        if (( count > 0 )); then
            printf '{"text":"󰇮 %d","class":"alert","tooltip":"Maildir %s: %d unread"}\n' "$count" "$root" "$count"
        else
            printf '{"text":"󰇯 0","class":"ok","tooltip":"Maildir %s: zero unread"}\n' "$root"
        fi
        exit 0
    fi
done

printf '{"text":"󰇮 · no setup","class":"empty","tooltip":"No notmuch DB and no ~/Mail or ~/.mail — install/configure a mail client to populate"}\n'
