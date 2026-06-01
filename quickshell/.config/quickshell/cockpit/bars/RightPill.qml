import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../generated"
import "../services"
import "../components"

// RIGHT pill — status: cpu · mem · temp · vol · now-playing · alerts · control · tray.
PanelWindow {
    id: win
    // compact = the secondary (narrow portrait) screen: system vitals + tray ONLY, so
    // the centered clock pill stays visible beside it. The main DP-2 bar stays full.
    property bool compact: false
    WlrLayershell.namespace: "cockpit"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; right: true }
    margins { top: Theme.gap; right: Theme.gap }
    exclusiveZone: 0   // reserve handled by niri struts (SSOT); pill only floats
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    color: "transparent"

    Pill {
        id: pill

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gCpu + " " + Vitals.cpu + "%"
            color: Vitals.cpu > 85 ? Theme.error : Theme.fg
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gMem + " " + Vitals.mem + "%"
            color: Vitals.mem > 90 ? Theme.error : Theme.fg
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gTemp + " " + Vitals.temp + "°"
            color: Vitals.temp > 80 ? Theme.error : Theme.fg
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
        }
        // GPU busy %
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gGpu + " " + Vitals.gpu + "%"
            color: Vitals.gpu > 92 ? Theme.error : Theme.semTextPrimary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }
        // frame-time — ~33ms at 30Hz; red if frames drop (guarantee #2 made visible)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gMonitoring + " " + Vitals.frameMs.toFixed(0) + "ms"
            color: Vitals.frameMs > 40 ? Theme.error : Theme.semTextSecondary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }

        Text { visible: !win.compact; text: "·"; color: Theme.fgMuted; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter }

        Text {
            visible: !win.compact
            anchors.verticalCenter: parent.verticalCenter
            text: (Audio.muted ? Theme.gMute : Theme.gSpeaker) + " " + Audio.volume + "%"
            color: Audio.muted ? Theme.fgMuted : Theme.fg
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightMetric
        }

        // now playing — only when media is active (ref: media module)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact && Audio.nowPlaying.length > 0
            text: Theme.gPlay + " " + Audio.nowPlaying
            color: Theme.fgMuted
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
            elide: Text.ElideRight
            width: visible ? Math.min(implicitWidth, 220) : 0
        }

        ScriptTile { visible: !win.compact; anchors.verticalCenter: parent.verticalCenter; script: "alerts.sh"; interval: 5000 }

        Text { visible: !win.compact; text: "·"; color: Theme.fgMuted; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter }

        // AI spend vs cap — today's cost against the daily budget (cost-cap hook).
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gSpend + " $" + Spend.spend.toFixed(2) + " / " + Spend.cap.toFixed(2)
            color: Spend.frac > 0.9 ? Theme.error : Spend.frac > 0.7 ? Theme.honey : Theme.semTextSecondary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Modals.toggle("ai") }
        }

        // Penalty Box — the AI team's governance at a glance: agents · N benched.
        // A first-class bar citizen (the concept): coloured by worst live severity,
        // click opens the Penalty Box modal.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gWarden + " " + Warden.summary.total + (Warden.benched > 0 ? " · " + Warden.benched + " benched" : " agents")
            color: Warden.benched > 0 ? Warden.sevColor(Warden.worstSeverity) : Theme.fgMuted
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
            font.weight: Warden.benched > 0 ? Theme.weightEmphasis : Theme.weightMetric
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Modals.toggle("penalty") }
        }

        // control center toggle (opens the right-side panel; mirrors Mod+Alt+C)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gControl
            color: (cca.containsMouse || CC.open) ? Theme.fg : Theme.fgMuted
            font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            MouseArea { id: cca; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: CC.toggle() }
        }

        Text { visible: !win.compact; text: "·"; color: Theme.fgMuted; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter }

        // system tray — rightmost, to the right of the clock + alerts (per design).
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap
            Repeater {
                model: SystemTray.items
                delegate: MouseArea {
                    required property var modelData
                    width: 18; height: 18
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (m) => { if (m.button === Qt.LeftButton) modelData.activate(); else modelData.secondaryActivate() }
                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }
        }
    }
}
