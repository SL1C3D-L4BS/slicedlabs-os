// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell.Io
import "../generated"

// ScriptTile — runs a reused Waybar chip script and renders its JSON chip as a
// spring-entrance tile. State class → token colour. Hides when the script emits
// empty (the guard, or genuine idle).
Rectangle {
    id: tile
    property string script: ""           // path under ~/.config/quickshell/cockpit/scripts/
    property int interval: 5000
    property string text: ""
    property string cls: "empty"
    property string tip: ""

    visible: text.length > 0
    radius: Theme.radius
    color: Qt.rgba(1, 1, 1, 0.045)
    implicitHeight: Theme.chipHeight - 8
    implicitWidth: lbl.implicitWidth + Theme.padX
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.82

    function col(c) {
        switch (c) {
        case "ok": case "success": return Theme.success
        case "info": return Theme.secondary
        case "warning": case "alert": return Theme.tertiary
        case "critical": case "fail": return Theme.error
        case "empty": return Theme.fgMuted
        default: return Theme.fg
        }
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: tile.text
        color: tile.col(tile.cls)
        font.family: Theme.mono
        font.pixelSize: Theme.uiSize
        Behavior on color { ColorAnimation { duration: Theme.normalMs } }
    }

    Process {
        id: p
        command: ["bash", "-c", "exec \"$HOME/.config/quickshell/cockpit/scripts/" + tile.script + "\""]
        stdout: StdioCollector {
            id: oc
            onStreamFinished: {
                var s = oc.text.trim()
                if (!s) { tile.text = ""; tile.cls = "empty"; return }
                try {
                    var j = JSON.parse(s)
                    tile.text = j.text || ""; tile.cls = j["class"] || "info"; tile.tip = j.tooltip || ""
                } catch (e) { tile.text = s; tile.cls = "info" }
            }
        }
    }
    Timer {
        interval: tile.interval; repeat: true; triggeredOnStart: true
        running: tile.script.length > 0
        onTriggered: if (!p.running) p.running = true
    }

    Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }
    Behavior on scale { NumberAnimation { duration: Theme.quickMs; easing.type: Easing.OutBack } }
}
