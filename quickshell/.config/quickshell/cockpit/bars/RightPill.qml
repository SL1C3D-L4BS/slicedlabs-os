// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Io
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

    // owned transport/volume surface for the media pill (playerctl/wpctl via cockpitctl)
    Process { id: mediaCtl }
    function mrun(c) { mediaCtl.command = ["bash", "-c", c]; mediaCtl.running = true }

    Pill {
        id: pill

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gCpu + " " + Vitals.cpu + "%"
            color: Vitals.cpu > 85 ? Theme.error : Theme.secondary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gMem + " " + Vitals.mem + "%"
            color: Vitals.mem > 90 ? Theme.error : Theme.wisteria
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gTemp + " " + Vitals.temp + "°"
            color: Vitals.temp > 80 ? Theme.error : Theme.tertiary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
        }
        // GPU busy %
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gGpu + " " + Vitals.gpu + "%"
            color: Vitals.gpu > 92 ? Theme.error : Theme.success
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }
        // frame-time — ~33ms at 30Hz; red if frames drop (guarantee #2 made visible)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.gMonitoring + " " + Vitals.frameMs.toFixed(0) + "ms"
            color: Vitals.frameMs > 40 ? Theme.error : Theme.honey
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        }

        Text { visible: !win.compact; text: "·"; color: Theme.fgMuted; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter }

        Text {
            visible: !win.compact
            anchors.verticalCenter: parent.verticalCenter
            text: (Audio.muted ? Theme.gMute : Theme.gSpeaker) + " " + Audio.volume + "%"
            color: Audio.muted ? Theme.fgMuted : Theme.secondary
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightMetric
        }

        // ── bluetooth — adapter/connection state, part of the audio cluster. Click opens
        // the device picker (bt modal). Shows the connected device's short name + battery%
        // beside the glyph; glyph-only when nothing is connected. Off → dimmed.
        MouseArea {
            id: bt
            visible: !win.compact
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: btRow.implicitWidth
            implicitHeight: btRow.implicitHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Stack.openSystem(1)
            Row {
                id: btRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.gap
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !Bt.enabled ? Theme.gBluetoothOff
                          : (Bt.connectedCount > 0 ? Theme.gBluetoothConnected : Theme.gBluetooth)
                    color: !Bt.enabled ? Theme.inactive
                          : Bt.connectedCount === 0 ? Theme.fgMuted
                          : (Bt.primaryBattery >= 0 && Bt.primaryBattery < 20) ? Theme.error
                          : Theme.secondary
                    font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightMetric
                    Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                }
                Text {
                    id: btLabel
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Bt.connectedCount > 0
                    text: Bt.primaryName + (Bt.primaryBattery >= 0 ? " " + Bt.primaryBattery + "%" : "")
                    color: Theme.fgMuted
                    font.family: Theme.mono; font.pixelSize: Theme.uiSize
                    elide: Text.ElideRight
                    // width via TextMetrics (NOT implicitWidth) to avoid an elide binding loop
                    width: Math.min(btLabelM.advanceWidth, 140)
                    TextMetrics { id: btLabelM; font: btLabel.font; text: btLabel.text }
                }
            }
        }

        // ── media — now-playing (mpd / local audio), ALWAYS present + clickable. Left-click
        // opens the player modal (art · transport · cava · Open music); middle-click toggles
        // play/pause; scroll over it changes volume. A tiny cava spectrum animates while playing.
        MouseArea {
            id: media
            visible: !win.compact
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: mediaRow.implicitWidth
            implicitHeight: mediaRow.implicitHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (m) => {
                if (m.button === Qt.MiddleButton) win.mrun("cockpitctl media toggle")
                else Stack.openSystem(2)
            }
            onWheel: (w) => win.mrun("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%" + (w.angleDelta.y > 0 ? "+" : "-"))

            Row {
                id: mediaRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.gap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.hasPlayer ? (Audio.isPlaying ? Theme.gPlay : Theme.gPause) : Theme.gMedia
                    color: Audio.isPlaying ? Theme.brand("media") : Theme.fgMuted
                    font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightMetric
                    Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                }

                // tiny live spectrum (cava) — only while actually playing
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Audio.isPlaying
                    spacing: 2
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            width: 2; radius: 1
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property real v: (Cava.bars && Cava.bars.length > index * 4)
                                ? Math.max(0, Math.min(1, Cava.bars[index * 4] / 100)) : 0
                            height: Math.max(2, v * Theme.uiSize)
                            color: Theme.brand("media")
                            Behavior on height { NumberAnimation { duration: Theme.quickMs } }
                        }
                    }
                }

                Text {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.nowPlaying.length > 0 ? Audio.nowPlaying
                          : Audio.hasPlayer ? Audio.sourceName : "Music"
                    color: Audio.nowPlaying.length > 0 ? Theme.fgMuted : Theme.inactive
                    font.family: Theme.mono; font.pixelSize: Theme.uiSize
                    elide: Text.ElideRight
                    // width via TextMetrics (NOT implicitWidth) to avoid an elide binding loop
                    width: Math.min(trackM.advanceWidth, 200)
                    TextMetrics { id: trackM; font: track.font; text: track.text }
                }
            }
        }

        ScriptTile { visible: !win.compact; anchors.verticalCenter: parent.verticalCenter; script: "alerts.sh"; interval: 5000 }

        Text { visible: !win.compact; text: "·"; color: Theme.fgMuted; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter }

        // AI spend vs cap — today's cost against the daily budget (cost-cap hook).
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gSpend + " $" + Spend.spend.toFixed(2) + " / " + Spend.cap.toFixed(2)
            color: Spend.frac > 0.9 ? Theme.error : Theme.honey
            font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Stack.openInspector(2) }
        }

        // Penalty Box — the AI team's governance at a glance: agents · N benched.
        // A first-class bar citizen (the concept): coloured by worst live severity,
        // click opens the Penalty Box modal.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gWarden + " " + Warden.summary.total + (Warden.benched > 0 ? " · " + Warden.benched + " benched" : " agents")
            color: Warden.benched > 0 ? Warden.sevColor(Warden.worstSeverity) : Theme.success
            font.family: Theme.mono; font.pixelSize: Theme.uiSize
            font.weight: Warden.benched > 0 ? Theme.weightEmphasis : Theme.weightMetric
            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Stack.openSystem(4) }
        }

        // hermes — the local AI assistant; click summons the modeless card (also Mod+Grave).
        // A first-class, always-visible launcher so the brain is never hidden behind a keybind.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: "✦"
            color: (bca.containsMouse || Stack.has("hermes")) ? Theme.brand("ai") : Theme.fgMuted
            font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            MouseArea { id: bca; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Stack.toggle("hermes") }
        }

        // System menu toggle (the consolidated Controls · Bluetooth · Media · Keys · Governance · Power)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !win.compact
            text: Theme.gControl
            color: (cca.containsMouse || Stack.has("system")) ? Theme.fg : Theme.fgMuted
            font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            MouseArea { id: cca; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Stack.openSystem(0) }
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
