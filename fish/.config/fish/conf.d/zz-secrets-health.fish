# zz-secrets-health.fish — at interactive login, WARN (never fail) when the
# rendered secrets are absent, so a fresh boot that skipped `render-secrets`
# doesn't silently leave a broken AI environment. Surface failures, don't hide
# them (A Philosophy of Software Design — a module shouldn't mask a failure).
if status is-interactive
    if not test -s "$HOME/.config/ai/keys.env"
        echo "⚠  secrets: ~/.config/ai/keys.env missing/empty — run: render-secrets" >&2
    end
end
