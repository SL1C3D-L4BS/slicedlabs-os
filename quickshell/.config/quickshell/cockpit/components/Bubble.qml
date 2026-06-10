// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"

// Bubble — a floating Liquid-Glass message/answer bubble: the conversational sibling of
// Pill's capsule. Part of the SlicedLabs modal language (pills · bubbles · cards). The
// PARENT sets the width; the bubble fits its content vertically. One Glass per surface
// (Apple law); `emphasis` bleeds the accent + turns on the focal material (the assistant's
// own voice) while plain bubbles stay calm/muted. All chrome rides [modal]/[geom] tokens.
Item {
    id: bubble
    property string text: ""
    property string glyph: ""
    property color accent: Theme.fgMuted
    property bool emphasis: false              // the assistant's voice vs a muted note
    default property alias extra: body.data     // optional content under the text

    implicitHeight: col.implicitHeight + Theme.modalPad * 2
    height: implicitHeight

    Glass {
        anchors.fill: parent
        radius: Theme.modalRadius
        tint: Theme.cssChip
        brand: bubble.emphasis ? bubble.accent : Theme.fgMuted
        tier: bubble.emphasis ? "focal" : "base"
    }

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.modalPad
        spacing: Theme.gap

        Text {
            visible: bubble.text.length > 0
            width: parent.width
            text: (bubble.glyph.length > 0 ? bubble.glyph + "  " : "") + bubble.text
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: Theme.uiSize
            wrapMode: Text.WordWrap
        }
        Item { id: body; width: parent.width; implicitHeight: childrenRect.height }
    }
}
