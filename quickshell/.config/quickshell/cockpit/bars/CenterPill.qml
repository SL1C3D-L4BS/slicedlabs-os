import QtQuick
import Quickshell
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// CENTER pill — the focal clock (ref: center "focal point" module). The bar's
// quiet anchor: time large, date muted beneath the rhythm of the workstation.
PanelWindow {
    id: win
    WlrLayershell.namespace: "cockpit"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true }
    margins {
        top: Theme.gap
        left: win.screen ? Math.round((win.screen.width - pill.implicitWidth) / 2) : Theme.gap
    }
    exclusiveZone: 0   // reserve handled by niri struts (SSOT); pill only floats
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    color: "transparent"

    Pill {
        id: pill

        Text {
            id: clk
            anchors.verticalCenter: parent.verticalCenter
            property var now: new Date()
            text: Qt.formatDateTime(now, "HH:mm")
            color: Theme.fg
            font.family: Theme.display
            font.pixelSize: Theme.headingMd
            font.weight: Theme.weightActive
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.now = new Date() }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(clk.now, "ddd d MMM")
            color: Theme.fgMuted
            font.family: Theme.mono
            font.pixelSize: Theme.uiSizeSm
        }
    }
}
