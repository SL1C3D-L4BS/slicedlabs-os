// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"

// ModalShell — the ONE userspace modal pill (the SlicedLabs modal design language; see
// library/codex/20-architect/modal-design-language.md). A centered Liquid-Glass
// floating pill: header (glyph · title) + hairline + content slot + the shared
// entrance (rise + fade). The HOST supplies the PanelWindow + scrim + Esc; drop a
// ModalShell inside it and centre it. ONE Glass per surface (Apple law) — content
// draws as siblings ON TOP. All chrome rides [modal]/[geom] tokens (no raw values).
Item {
    id: shell

    // ---- API ----
    property string title: ""
    property string glyph: ""                  // optional leading glyph (Theme.g*)
    property color accent: Theme.fgMuted       // glyph hue + Glass ambient bleed
    property int widthTier: Theme.modalWidth   // modalWidthSm | modalWidth | modalWidthLg
    property bool animate: true                // play the entrance when shown
    default property alias content: body.data  // the modal body

    width: widthTier
    implicitWidth: widthTier
    implicitHeight: col.implicitHeight + Theme.modalPad * 2
    height: implicitHeight

    function play() { if (animate) { popScale.restart(); popFade.restart() } }
    NumberAnimation { id: popScale; target: shell; property: "scale"; from: Theme.modalEnterScale; to: 1.0; duration: Theme.slowMs; easing.type: Easing.OutCubic }
    NumberAnimation { id: popFade;  target: shell; property: "opacity"; from: 0.0; to: 1.0; duration: Theme.normalMs }
    Component.onCompleted: play()

    // the pill — Liquid Glass surface + swallow, content on top
    Glass { anchors.fill: parent; radius: Theme.modalRadius; tint: Theme.cssChip; brand: shell.accent; tier: "ultra" }
    MouseArea { anchors.fill: parent }         // swallow clicks (the host scrim dismisses)

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.modalPad
        spacing: Theme.modalGap

        Row {
            id: hdr
            visible: shell.title.length > 0 || shell.glyph.length > 0
            width: parent.width
            height: visible ? Theme.modalHeaderHeight : 0
            spacing: Theme.gap
            Text { visible: shell.glyph.length > 0; anchors.verticalCenter: parent.verticalCenter; text: shell.glyph; color: shell.accent; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
            Text { anchors.verticalCenter: parent.verticalCenter; text: shell.title; color: Theme.fg; font.bold: true; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
        }
        Rectangle { visible: hdr.visible; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, Theme.modalHairline) }

        Item {
            id: body
            width: parent.width
            implicitHeight: childrenRect.height
        }
    }
}
