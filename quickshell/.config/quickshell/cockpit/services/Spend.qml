pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Spend — the AI team's cost link. Execs `slicedlabs-spend` for today's spend + the
// daily cap (from the audit ledger via the cost-cap hook) → the bar's `ai $spend / cap`
// pill. Cheap: one sample every 12s.
Singleton {
    id: root
    property real spend: 0
    property real cap: 0
    readonly property real frac: cap > 0 ? Math.min(1, spend / cap) : 0

    Process {
        id: p
        command: ["slicedlabs-spend"]
        stdout: StdioCollector {
            id: sc
            onStreamFinished: {
                var parts = sc.text.trim().split(/\s+/)
                if (parts.length >= 2) { root.spend = parseFloat(parts[0]); root.cap = parseFloat(parts[1]) }
            }
        }
    }
    Timer { interval: 12000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!p.running) p.running = true }
}
