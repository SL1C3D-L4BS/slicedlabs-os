import QtQuick
import Quickshell
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// LEFT pill — navigation + context: ☰ menu · workspace switcher (named, brand-hued)
// · active-window title. The reference puts workspaces left; we keep the NAMES (our
// identity) and lead with the menu, trail with what you're looking at.
PanelWindow {
    id: win
    WlrLayershell.namespace: "cockpit"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true }
    margins { top: Theme.gap; left: Theme.gap }
    exclusiveZone: 0   // reserve handled by niri struts (SSOT); pill only floats
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    color: "transparent"

    Pill {
        id: pill

        // ☰ menu — slides down system options · keybindings · appearance · palette.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Theme.barHeight - 12
            implicitHeight: Theme.barHeight - 12
            Text {
                anchors.centerIn: parent
                text: "☰"
                color: (hbg.containsMouse || Menu.open) ? Theme.fg : Theme.fgMuted
                font.family: Theme.mono
                font.pixelSize: Theme.headingMd
                Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            }
            MouseArea { id: hbg; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Menu.toggle() }
        }

        // workspace pager — number + identity dot + CAPITALIZED name (the design
        // concept). The focused tab gets a 2px border in its OWN identity hue + a
        // soft fill; the rest dim. Click focuses; a badge counts its windows.
        Row {
            id: wsRow
            readonly property var wsOrder: ["coding", "research", "engine", "browser", "monitoring", "streaming", "gaming", "media"]
            spacing: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: Niri.workspaces
                    .filter(function (w) { return wsRow.wsOrder.indexOf(w.name) >= 0 })
                    .sort(function (a, b) { return wsRow.wsOrder.indexOf(a.name) - wsRow.wsOrder.indexOf(b.name) })
                delegate: Rectangle {
                    id: tab
                    required property var modelData
                    readonly property color hue: Theme.brand(modelData.name)
                    readonly property bool active: modelData.focused
                    readonly property int wins: Niri.windowCount(modelData.id)
                    implicitWidth: tabRow.implicitWidth + 2 * Theme.gap
                    implicitHeight: Theme.barHeight - 12
                    radius: height / 2
                    color: active ? Qt.rgba(tab.hue.r, tab.hue.g, tab.hue.b, 0.12) : "transparent"
                    border.width: active ? Theme.pagerActiveBorder : 0
                    border.color: tab.hue
                    Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                    Behavior on border.width { NumberAnimation { duration: Theme.normalMs } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: Theme.unit + 2
                        // 1-based canonical workspace number (fixed by identity order)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: wsRow.wsOrder.indexOf(tab.modelData.name) + 1
                            color: Theme.semTextTertiary
                            font.family: Theme.mono
                            font.pixelSize: Theme.uiSizeSm
                            font.weight: Theme.weightMetric
                        }
                        // identity dot
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.pagerDot; height: Theme.pagerDot; radius: width / 2
                            color: tab.hue
                            opacity: tab.active ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }
                        }
                        // CAPITALIZED identity name (case from [cockpit].workspace_label_case)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Theme.workspaceLabel(tab.modelData.name)
                            color: tab.active ? Theme.semTextPrimary : Theme.semTextSecondary
                            font.family: Theme.display
                            font.pixelSize: Theme.uiSize
                            font.weight: tab.active ? Theme.weightEmphasis : Theme.weightDim
                            font.capitalization: Theme.workspaceLabelCase === "small_caps" ? Font.SmallCaps : Font.MixedCase
                            Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                        }
                        // live window-count badge (only when populated)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tab.wins > 0
                            text: tab.wins
                            color: Theme.semTextTertiary
                            font.family: Theme.mono
                            font.pixelSize: Theme.uiSizeSm
                            font.weight: Theme.weightMetric
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWorkspace(tab.modelData.name)
                    }
                }
            }
        }

        // thin separator
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 14; radius: 0.5; color: Qt.rgba(1, 1, 1, 0.12) }

        // active window title
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Niri.activeWindow
            visible: Niri.activeWindow.length > 0
            color: Theme.fgMuted
            font.family: Theme.mono
            font.pixelSize: Theme.uiSize
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 280)
        }
    }
}
