pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Cava — audio FFT feed for the Reactor (stream/media reactivity). Runs cava in
// raw-ascii mode; `level` is the normalised peak across bars (0..1), smoothed.
Singleton {
    id: root
    property real level: 0.0
    property var bars: []

    Process {
        id: p
        command: ["bash", "-c", "exec cava -p \"$HOME/.config/quickshell/cockpit/core/cava.conf\""]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split(";")
                var peak = 0, arr = []
                for (var i = 0; i < parts.length; i++) {
                    var v = parseInt(parts[i])
                    if (!isNaN(v)) { arr.push(v); if (v > peak) peak = v }
                }
                if (arr.length === 0) return
                root.bars = arr
                var target = Math.min(1.0, peak / 100.0)
                root.level = root.level * 0.6 + target * 0.4   // smoothing
            }
        }
    }
}
