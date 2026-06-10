// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// LEFT pill — navigation + context: ☰ menu · workspace switcher (official glyphs,
// brand-hued) · active-window title. The reference puts workspaces left; we lead with
// the menu and trail with what you're looking at.
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

        // Marketplace — the storefront glyph opens the SlicedLabs layer (the independent
        // left-anchored panel). Replaces the old ☰ menu, whose options now live in the System card.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Theme.barHeight - 12
            implicitHeight: Theme.barHeight - 12
            Text {
                anchors.centerIn: parent
                text: Theme.gMarket
                color: (hbg.containsMouse || Market.open) ? Theme.honey : Theme.fgMuted
                font.family: Theme.mono
                font.pixelSize: Theme.headingMd
                Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            }
            MouseArea { id: hbg; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Market.toggle() }
        }

        // workspace pager — canonical number + official identity glyph (in its hue).
        // The focused tab gets a 2px border in its OWN identity hue + a soft fill; the
        // rest dim. Click focuses; a badge counts its windows.
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
                        // official identity glyph — the workspace's own icon (tokens [icon]),
                        // tinted in its identity hue. Replaces the text name AND the (now
                        // redundant) identity dot: the hued glyph IS the identity marker.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Theme.glyph(tab.modelData.name)
                            color: tab.active ? tab.hue : Qt.rgba(tab.hue.r, tab.hue.g, tab.hue.b, 0.6)
                            font.family: Theme.mono
                            font.pixelSize: Theme.uiSizeLg
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
            // Responsive cap: the title shrinks so the left-anchored pill always stops short of
            // the screen-CENTERED clock (CenterPill) — never overlapping it, never clipping the
            // pager. Adapts to the live pager width; floors at 48px (just enough to read a prefix).
            width: Math.min(implicitWidth,
                            Math.max(48, (win.screen ? win.screen.width : 2560) / 2 - wsRow.width - 200))
        }
    }
}
