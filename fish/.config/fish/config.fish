# [ENGINE] platform — fish shell config

if status is-interactive
    # Prompt: tide (powerline capsules, configured from tokens in conf.d/sl-tide.fish).
    # tide installs its own autoloaded fish_prompt — no init line needed here.
    zoxide init fish | source
    # mise — polyglot runtime manager (Go, Node, Zig, Ruby, …); rustup owns Rust.
    mise activate fish | source
    # direnv — per-project environment loaded from .envrc on cd.
    direnv hook fish | source
end

set -gx EDITOR nvim
set -gx VISUAL nvim
set -g fish_greeting

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/tools/FlameGraph
fish_add_path $HOME/tools/osxcross/target/bin

# Auto-start Niri on TTY1 login — no display manager (spec XVIII.2).
# niri-session re-execs itself through the login shell, which re-sources this
# file; the exported NIRI_AUTOSTART sentinel survives the exec→bash→fish chain
# so the second pass skips the guard instead of recursing forever. (audit F1)
if status is-login; and test -z "$WAYLAND_DISPLAY"; and test -z "$NIRI_AUTOSTART"; and test (tty) = /dev/tty1
    set -gx NIRI_AUTOSTART 1
    exec niri-session
end
