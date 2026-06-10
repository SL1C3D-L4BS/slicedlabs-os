// SlicedLabs · body · © 2026 SlicedLabs
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

    // Material tier (Liquid Retina v3): base = always-on chrome (pills/bars —
    // liquid but static); focal = menu/Marketplace/secondary panels (sweep);
    // ultra = the showpiece (Stack modals · Control Center · permission · lock).
    property string tier: "base"  // base | focal | ultra
    property bool focal: false    // DEPRECATED alias for tier:"focal" (callers migrated)
    readonly property string _tier: tier !== "base" ? tier : (focal ? "focal" : "base")

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
        property real refraction: root._tier === "ultra" ? Theme.glassUltraRefractionPx
                                : root._tier === "focal" ? Theme.glassFocalRefractionPx
                                : Theme.glassRefractionPx
        property real rimWidth: Theme.glassRimWidth
        property real rimOpacity: root._tier === "ultra" ? Theme.glassUltraRimOpacity
                                : root._tier === "focal" ? Theme.glassFocalRimOpacity
                                : Theme.glassRimOpacity
        property real specIntensity: root._tier === "ultra" ? Theme.glassUltraSpecularIntensity
                                   : root._tier === "focal" ? Theme.glassFocalSpecularIntensity
                                   : Theme.glassSpecularIntensity
        property real specSpeed: root._tier === "ultra" ? Theme.glassUltraSpecularSpeed
                               : root._tier === "focal" ? Theme.glassFocalSpecularSpeed
                               : Theme.glassSpecularSpeed
        property real chromatic: root._tier === "ultra" ? Theme.glassUltraChromaticPx
                               : root._tier === "focal" ? Theme.glassFocalChromaticPx
                               : Theme.glassChromaticPx
        property real ambientBleed: root._tier === "ultra" ? Theme.glassUltraAmbientBleed
                                  : root._tier === "focal" ? Theme.glassFocalAmbientBleed
                                  : Theme.glassAmbientBleed
        property real quality: root._quality
        property real reduceMotion: Theme.glassReduceMotion
        property real rimBrandMix: Theme.glassRimBrandMix
        property color tint: root.tint
        property color brand: root.brand
        property vector4d wallRect: root.wallRect
        property var wallpaper: wallTex

        fragmentShader: Qt.resolvedUrl("../core/shaders/glass.frag.qsb")

        // Bars are calm/static (tier "base" → no FrameAnimation, time stays 0, zero
        // per-frame cost — the v3 base sheen is STATIC). focal/ultra surfaces
        // animate the liquid specular sweep below.
        Behavior on brand { ColorAnimation { duration: Theme.slowMs } }
        FrameAnimation {
            running: root._tier !== "base" && fx.visible && Theme.glassReduceMotion < 0.5
            onTriggered: fx.time += frameTime
        }
    }
}
