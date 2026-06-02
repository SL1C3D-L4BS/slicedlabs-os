function gt --description 'plain terminal — a ghostty window with NO AI pane (zellij `bare` layout)'
    # The opt-out from the Claude-attached default (spec §11.1): `gt` opens a throwaway
    # terminal that is just your shell + the pill bar, no governed AI pane. Reuses the
    # existing `bare` zellij layout via the `zj` wrapper. setsid -f fully detaches so it
    # outlives the launching shell. Extra args pass through to `zj bare`.
    setsid -f ghostty -e zj bare $argv >/dev/null 2>&1
end
