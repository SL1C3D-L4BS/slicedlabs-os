import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// MenuDropdown — the ☰ menu. A frosted panel just under the CenterPill that
// SLIDES DOWN (clip + height-reveal + fade) carrying system options, the
// keybindings overlay, theme toggle, and the full command palette. Summoned by
// Menu.toggle() (the hamburger in CenterPill); dismissed by click-out or Esc.
// Namespace "cockpit-modal" inherits the niri blur + screencast-block layer-rule.
PanelWindow {
    id: win
    visible: Menu.open || reveal.height > 1
    WlrLayershell.namespace: "cockpit-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    Process { id: act }
    function run(cmd) { act.command = ["bash", "-c", cmd]; act.running = true; Menu.close() }

    // click anywhere outside the panel to dismiss
    MouseArea { anchors.fill: parent; onClicked: Menu.close() }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.gap + Theme.barHeight + Theme.gap   // just below the center pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: 440
        height: reveal.height

        Item {
            id: reveal
            width: parent.width
            clip: true                                   // reveal grows downward = slides down
            height: Menu.open ? content.implicitHeight + Theme.gapLg * 2 : 0
            opacity: Menu.open ? 1 : 0
            Behavior on height { NumberAnimation { duration: Theme.slowMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }

            Glass { anchors.fill: parent; radius: Theme.radiusLg; tint: Theme.cssChip; focal: true }
            MouseArea { anchors.fill: parent }           // swallow clicks on the panel

            Column {
                id: content
                anchors.top: parent.top
                anchors.topMargin: Theme.gapLg
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.gapLg * 2
                spacing: Theme.gap

                // ---- SYSTEM ----
                Text { text: "SYSTEM"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                Row {
                    width: parent.width
                    spacing: Theme.gap
                    property var acts: [
                        ["lock", "loginctl lock-session"],
                        ["suspend", "systemctl suspend"],
                        ["logout", "niri msg action quit"],
                        ["reboot", "systemctl reboot"],
                        ["shutdown", "systemctl poweroff"]
                    ]
                    Repeater {
                        model: parent.acts
                        delegate: Rectangle {
                            required property var modelData
                            width: (content.width - Theme.gap * 4) / 5
                            height: 38
                            radius: Theme.radius
                            color: pa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                            Text { anchors.centerIn: parent; text: modelData[0]; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                            MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.run(modelData[1]) }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.06) }

                // ---- keybindings · appearance · more ----
                Repeater {
                    model: [
                        ["Keybindings",     "searchable keys · Mod+Alt+K",  "$HOME/.local/bin/cockpitctl modal keys"],
                        ["Toggle theme",    "dark / light — hot-reloads",   "$HOME/.local/bin/cockpitctl theme toggle"],
                        ["Command palette", "all workstation actions",      "$HOME/.local/bin/sliced-menu"]
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: content.width
                        height: 46
                        radius: Theme.radius
                        color: ra.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.padX
                            spacing: 2
                            Text { text: modelData[0]; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightLabel }
                            Text { text: modelData[1]; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                        }
                        MouseArea { id: ra; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.run(modelData[2]) }
                    }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: Menu.open; onActivated: Menu.close() }
}
