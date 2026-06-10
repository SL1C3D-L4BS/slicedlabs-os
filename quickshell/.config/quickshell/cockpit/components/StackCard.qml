// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"
import "../services"

// StackCard — a floating Liquid-Glass card in the modeless modal stack (snapped under the
// RightPill by ModalStack). Header (glyph · title · × close → Stack.close(id)) + content slot +
// rise/fade entrance. NO backdrop — the desktop stays sharp; the card wears the ULTRA
// showpiece material (Liquid Retina v3: deep lensing, chromatic edge, slow sweep) while
// you work alongside it. The parent (the stack Column) sets the width.
Item {
    id: c
    property string modalId: ""
    property string title: ""
    property string glyph: ""
    property color accent: Theme.fgMuted
    default property alias content: body.data

    width: parent ? parent.width : Theme.modalWidth
    implicitHeight: col.implicitHeight + Theme.modalPad * 2
    height: implicitHeight

    opacity: 0
    scale: Theme.modalEnterScale
    Component.onCompleted: { c.opacity = 1; c.scale = 1 }
    Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }
    Behavior on scale { NumberAnimation { duration: Theme.slowMs; easing.type: Easing.OutCubic } }

    Glass { anchors.fill: parent; radius: Theme.modalRadius; tint: Theme.cssChip; brand: c.accent; tier: "ultra" }

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.modalPad
        spacing: Theme.modalGap

        Item {
            width: parent.width
            height: Theme.modalHeaderHeight
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.gap
                Text { visible: c.glyph.length > 0; anchors.verticalCenter: parent.verticalCenter; text: c.glyph; color: c.accent; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
                Text { anchors.verticalCenter: parent.verticalCenter; text: c.title; color: Theme.fg; font.bold: true; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26; radius: 13
                color: xm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                Text { anchors.centerIn: parent; text: "✕"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Stack.close(c.modalId) }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, Theme.modalHairline) }
        Item { id: body; width: parent.width; implicitHeight: childrenRect.height }
    }
}
