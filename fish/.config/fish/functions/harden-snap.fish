function harden-snap --description 'Bracket a system change with snapper pre/post snapshots'
    argparse 'c/config=' -- $argv
    or return 1

    set -l cfg root
    set -q _flag_config; and set cfg $_flag_config

    if test (count $argv) -lt 1
        echo "usage: harden-snap [-c root|home] DESCRIPTION [-- COMMAND...]" >&2
        return 2
    end

    set -l desc $argv[1]
    set -l cmd $argv[2..-1]

    set -l pre (sudo snapper -c $cfg create -t pre -d "$desc (pre)" -p)
    or begin
        echo "harden-snap: pre-snapshot failed on -c $cfg" >&2
        return 3
    end
    echo "harden-snap: pre=#$pre cfg=$cfg desc=\"$desc\""

    set -l rc 0
    if test (count $cmd) -gt 0
        $cmd
        set rc $status
    else
        echo "harden-snap: apply your change, then press Enter for the post-snapshot..."
        read -P "> "
    end

    set -l post (sudo snapper -c $cfg create -t post --pre-number $pre -d "$desc (post)" -p)

    echo
    echo "harden-snap: cfg=$cfg pre=#$pre post=#$post"
    echo "harden-snap: rollback -> sudo snapper -c $cfg undochange $pre..$post"
    return $rc
end
