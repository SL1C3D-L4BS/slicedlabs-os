function slc --description 'SlicedLabs OS command — focus a workspace + realize its cockpit (spec §16)'
    # `slc` is the ergonomic front-end to the declarative scene machinery: it focuses
    # the niri workspace, then hands off to `cockpit <ws>` (lib/scene.sh) which is the
    # SSOT realizer — idempotent, niri-routed, identity-tinted, ambient-aware. We do
    # NOT reimplement window spawning here; the registry (workspaces.toml) owns that.
    set -l known coding engine browser monitoring research streaming gaming media

    switch "$argv[1]"
        case os
            switch "$argv[2]"
                case doctor
                    verify-all
                case install
                    bootstrap.sh $argv[3..-1]
                case '*'
                    echo "slc os <doctor|install …>" >&2
                    return 1
            end
        case -l --list list
            cockpit --list
        case '' -h --help help
            echo "slc <workspace>   focus + realize a cockpit:"
            echo "                  "(string join ' · ' $known)
            echo "slc scene <ws>    explicit form (spec §16)"
            echo "slc os doctor     run verify-all (the system health gate)"
            echo "slc os install …  drive bootstrap.sh"
            echo "slc --list        show the scene registry"
        case scene
            # explicit `slc scene <ws>` → delegate to the shorthand
            slc $argv[2..-1]
        case '*'
            set -l ws $argv[1]
            if not contains -- $ws $known
                echo "slc: unknown workspace '$ws' (known: "(string join ', ' $known)")" >&2
                return 1
            end
            niri msg action focus-workspace $ws 2>/dev/null
            cockpit $ws
    end
end
