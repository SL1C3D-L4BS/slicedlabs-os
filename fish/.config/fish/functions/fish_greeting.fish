# SlicedLabs · body · © 2026 SlicedLabs
# fish_greeting — the branded terminal greeting (fastfetch: SLICEDLABS wordmark
# + system info). Fires ONCE per terminal session, not per zellij pane: outside
# zellij always; inside zellij only in the session's first pane (pane 0).
function fish_greeting
    status is-interactive; or return
    isatty stdout; or return
    command -q fastfetch; or return
    if set -q ZELLIJ; and test "$ZELLIJ_PANE_ID" != 0
        return
    end
    fastfetch
end
