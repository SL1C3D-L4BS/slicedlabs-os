# SlicedLabs — eza colours. Rides the [ansi] SSOT: eza's UI elements use the 16
# terminal colours (codes 0-7/30-37), so `eza` is ALWAYS in sync with tokens.toml
# [ansi] by construction — no render step, no second palette to drift (same law as
# bat/fastfetch/rmpc). Chrome that wants identity lives in fzf/nvim/zellij, not here.
status is-interactive; or exit 0

set -gx EZA_ICONS_AUTO 1
# di dir · ex exec · ln symlink · da date · uu you · gu group · sn/sb size · ur/uw/ux perms
set -gx EZA_COLORS "di=1;34:ex=1;32:ln=36:da=37:uu=37:gu=37:sn=36:sb=36:ur=33:uw=31:ux=32:ue=32:gr=33:gw=31:gx=32:tr=33:tw=31:tx=32:xx=90:.=90:in=90"

# friendly default flags: icons, git status, grouped dirs, human sizes
abbr -ag ls 'eza --icons --group-directories-first'
abbr -ag ll 'eza --icons --group-directories-first -lah --git'
abbr -ag lt 'eza --icons --group-directories-first --tree --level=2'
