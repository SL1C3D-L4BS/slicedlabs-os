import QtQuick
import "../generated"

// Pill — a floating Liquid Glass container. Children are laid out in a horizontal
// Row ON TOP of a single Glass surface (core/shaders/glass.frag): procedural
// specular / Fresnel rim / chromatic + wallpaper edge-lensing, over niri's real
// backdrop blur (namespace="cockpit"). Set `brand` to bleed a workspace hue.
Item {
    id: pill
    default property alias content: inner.data
    property real hpad: Theme.gapLg
    property color brand: Theme.fgMuted          // ambient-bleed hue

    implicitWidth: inner.implicitWidth + hpad * 2
    implicitHeight: Theme.barHeight

    Glass {
        anchors.fill: parent
        radius: pill.height / 2          // capsule — sleek, principled (ref AuroraSurface)
        tint: Theme.cssChip
        brand: pill.brand
    }

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: Theme.gap
    }
}
