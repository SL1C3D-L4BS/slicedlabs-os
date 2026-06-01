pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Build — engine build state for the Reactor (unguarded; reads the same
// ~/.cache/engine-build-status that workstation.sh uses, plus live bacon).
Singleton {
    id: root
    property bool bacon: false
    property string state: "unknown"          // ok | fail | building | unknown
    readonly property bool building: bacon || state === "building"
    readonly property bool ok: state === "ok"
    readonly property bool fail: state === "fail"

    Process {
        id: p
        command: ["bash", "-c",
            "b=0; pgrep -x bacon >/dev/null 2>&1 && b=1;" +
            "s=unknown; f=\"${XDG_CACHE_HOME:-$HOME/.cache}/engine-build-status\";" +
            "[ -f \"$f\" ] && s=$(jq -r '.state // \"unknown\"' \"$f\" 2>/dev/null);" +
            "printf '{\"bacon\":%d,\"state\":\"%s\"}' \"$b\" \"$s\""]
        stdout: StdioCollector {
            id: bc
            onStreamFinished: { try { var j = JSON.parse(bc.text); root.bacon = !!j.bacon; root.state = j.state } catch (e) {} }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!p.running) p.running = true }
}
