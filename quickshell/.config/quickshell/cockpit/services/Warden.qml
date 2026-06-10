// SlicedLabs · body · © 2026 SlicedLabs
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../generated"

// Warden — the cockpit's governance link. Reads generated/governance.json (baked
// by render-governance from governance.toml + the ledger) and exposes the Penalty
// Box contract to the bar `agents · N benched` pill and the modal. Re-reads on a
// light timer so `warden rehab/retire` (and, later, the async monitor) reflect
// within ~2.5s; reload() refreshes immediately after an action.
Singleton {
    id: root
    property var summary: ({ clean: 0, benched: 0, suspended: 0, probation: 0, retired: 0, total: 0 })
    property var agents: []
    readonly property int benched: summary.benched || 0

    // worst live severity across the roster (drives the bar pill colour)
    readonly property string worstSeverity: {
        var w = ""
        for (var i = 0; i < agents.length; i++) {
            var s = agents[i].severity
            if (s === "red") return "red"
            if (s === "orange") w = "orange"
            else if (s === "yellow" && w === "") w = "yellow"
        }
        return w
    }

    function sevColor(sev) {
        return sev === "red" ? Theme.error
             : sev === "orange" ? Theme.tertiary
             : sev === "yellow" ? Theme.honey
             : Theme.success
    }

    Process {
        id: rd
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/cockpit/generated/governance.json"]
        stdout: StdioCollector {
            id: govOut
            onStreamFinished: {
                try {
                    var d = JSON.parse(govOut.text)
                    if (d.summary) root.summary = d.summary
                    root.agents = d.agents || []
                } catch (e) { /* keep last good contract */ }
            }
        }
    }
    function reload() { rd.running = true }
    Component.onCompleted: reload()
    Timer { interval: 2500; running: true; repeat: true; onTriggered: rd.running = true }
}
