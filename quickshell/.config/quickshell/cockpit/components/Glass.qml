import QtQuick
import Quickshell
import "../generated"
import "../services"

// Glass — the Cockpit's shared Liquid Glass material (core/shaders/glass.frag).
// Procedural specular / Fresnel rim / chromatic + edge-lensing of the current
// wallpaper, composited OVER niri's real dual-kawase blur. ONE Glass per surface
// (Apple law: no glass-on-glass); draw content as siblings ON TOP of this.
Item {
    id: root
    property real radius: Theme.radiusLg
    property color tint: Theme.cssChip          // frosted fill
    property color brand: Theme.fgMuted         // ambient-bleed hue (override per surface)
    property vector4d wallRect: Qt.vector4d(0, 0, 1, 1)  // surface→wallpaper UV (edge-only reveal)
    property bool focal: false  // FOCAL (modals/CC/menu/lock) → dimensional Liquid Glass; bars stay calm

    // Per-cockpit glass (spec §14): the FOCUSED workspace's tier picks the shader
    // budget — engine/gaming/streaming/media drop to a cheaper path so frame-time is
    // protected; the glass workspaces keep the full material. Reactive on Niri.focused.
    // "off" → flat frost; if the wallpaper texture isn't ready yet, fall back to low
    // (skips the sampler) so we never lens a null texture to black.
    readonly property string _wsQuality: Theme.glassQualityFor(Niri.focused)
    readonly property real _quality:
        _wsQuality === "off" ? 0.0
        : wallImg.status !== Image.Ready ? 0.5
        : _wsQuality === "low" ? 0.4
        : _wsQuality === "medium" ? 0.7
        : 1.0

    Image {
        id: wallImg
        source: "file://" + Quickshell.env("HOME") + "/.cache/engine-backdrop.png"
        visible: false
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 640                    // downscaled — only revealed at the rim
        width: 640
        height: 360
    }
    ShaderEffectSource {
        id: wallTex
        sourceItem: wallImg
        hideSource: true
        live: false                              // static wallpaper — no per-frame capture
        visible: false
    }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        property real time: 0
        property size rectSize: Qt.size(root.width, root.height)
        property real radius: root.radius
        property real refraction: root.focal ? Theme.glassFocalRefractionPx : Theme.glassRefractionPx
        property real rimWidth: Theme.glassRimWidth
        property real rimOpacity: root.focal ? Theme.glassFocalRimOpacity : Theme.glassRimOpacity
        property real specIntensity: root.focal ? Theme.glassFocalSpecularIntensity : Theme.glassSpecularIntensity
        property real specSpeed: root.focal ? Theme.glassFocalSpecularSpeed : Theme.glassSpecularSpeed
        property real chromatic: root.focal ? Theme.glassFocalChromaticPx : Theme.glassChromaticPx
        property real ambientBleed: root.focal ? Theme.glassFocalAmbientBleed : Theme.glassAmbientBleed
        property real quality: root._quality
        property real reduceMotion: Theme.glassReduceMotion
        property color tint: root.tint
        property color brand: root.brand
        property vector4d wallRect: root.wallRect
        property var wallpaper: wallTex

        fragmentShader: Qt.resolvedUrl("../core/shaders/glass.frag.qsb")

        // Bars are calm/static (focal:false → no FrameAnimation, time stays 0, zero
        // per-frame cost). FOCAL surfaces animate the liquid specular sweep below.
        Behavior on brand { ColorAnimation { duration: Theme.slowMs } }
        FrameAnimation {
            running: root.focal && fx.visible && Theme.glassReduceMotion < 0.5
            onTriggered: fx.time += frameTime
        }
    }
}
