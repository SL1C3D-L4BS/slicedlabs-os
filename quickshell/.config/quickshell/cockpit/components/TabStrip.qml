// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"

// TabStrip — the modal tab strip (independent sessions / sections). Token-driven;
// emits selected(index); wraps to extra rows when the tabs exceed the width.
// Model items: { label, glyph? }.
Flow {
    id: strip
    property var tabs: []
    property int current: 0
    property color accent: Theme.semBorderInfo  // active-tab underline (pass a brand/ramp hue)
    signal selected(int index)

    spacing: Theme.gap

    Repeater {
        model: strip.tabs
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool active: index === strip.current
            height: Theme.modalTabHeight
            implicitWidth: tlabel.implicitWidth + Theme.padX * 2
            radius: Theme.radius
            color: active ? Qt.rgba(1, 1, 1, Theme.modalFillHover)
                          : (tm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillSubtle) : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }

            Row {
                id: tlabel
                anchors.centerIn: parent
                spacing: 6
                Text { visible: !!modelData.glyph; anchors.verticalCenter: parent.verticalCenter; text: modelData.glyph || ""; color: active ? Theme.fg : Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label || ""; color: active ? Theme.fg : Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: active ? Theme.weightActive : Theme.weightLabel }
            }
            Rectangle { visible: active; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - Theme.padX; height: 2; radius: 1; color: strip.accent; Behavior on color { ColorAnimation { duration: Theme.normalMs } } }
            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: strip.selected(index) }
        }
    }
}
