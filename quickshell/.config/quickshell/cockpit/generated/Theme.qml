pragma Singleton
import QtQuick
import Quickshell

// GENERATED from ~/.dotfiles/system/tokens.toml by `render-quickshell`.
// variant: dark.  DO NOT EDIT — edit tokens.toml then re-run render-quickshell.
Singleton {
    id: theme
    readonly property string variant: "dark"
    readonly property bool light: false

    // ---- semantic colours ([color]) ----
    readonly property color bg: "#1E1E1E"
    readonly property color bgAlt: "#2B2B2B"
    readonly property color bgAltLight: "#3A3A3A"
    readonly property color fg: "#F7F6F2"
    readonly property color fgMuted: "#B8A789"
    readonly property color primary: "#2961B1"
    readonly property color secondary: "#64A8E5"
    readonly property color tertiary: "#D9892B"
    readonly property color error: "#D95C5C"
    readonly property color success: "#C7D42B"
    readonly property color coding: "#378ADD"
    readonly property color research: "#7F77DD"
    readonly property color engine: "#D85A30"
    readonly property color browser: "#1D9E75"
    readonly property color monitoring: "#639922"
    readonly property color streaming: "#D4537E"
    readonly property color gaming: "#E24B4A"
    readonly property color media: "#BA7517"
    readonly property color net: "#2FA39A"
    readonly property color ai: "#C264B0"
    readonly property color agenda: "#D98AAE"
    readonly property color selection: "#1A3D6F"
    readonly property color inactive: "#3D3528"
    readonly property color warmShadow: "#1A1612"
    readonly property color overlay: Qt.rgba(0.1176, 0.1176, 0.1176, 0.85)
    readonly property color mist: "#BED7F4"
    readonly property color sand: "#D3C399"
    readonly property color earth: "#7A6142"
    readonly property color wisteria: "#7C6ED6"
    readonly property color honey: "#D6BF3A"
    readonly property color brick: "#8E3A32"

    // ---- GTK/rgba surfaces + glows ([color_css]) ----
    readonly property color cssBackdrop: Qt.rgba(0.1176, 0.1176, 0.1176, 0.85)
    readonly property color cssBgAltSoft: Qt.rgba(0.1686, 0.1686, 0.1686, 0.78)
    readonly property color cssChip: Qt.rgba(0.1686, 0.1686, 0.1686, 0.85)
    readonly property color cssOverlayDim: Qt.rgba(0.0000, 0.0000, 0.0000, 0.6)
    readonly property color cssShadowDim: Qt.rgba(0.0000, 0.0000, 0.0000, 0.5)
    readonly property color cssGlowBuild: Qt.rgba(0.3922, 0.6588, 0.8980, 0.4)
    readonly property color cssGlowRec: Qt.rgba(0.8510, 0.5373, 0.1686, 0.5)
    readonly property color cssGlowLive: Qt.rgba(0.8510, 0.3608, 0.3608, 0.5)
    readonly property color cssGlowUrgent: Qt.rgba(0.8510, 0.5373, 0.1686, 0.69)

    // ---- glyphs ([icon]) ----
    readonly property string gOk: "✓"
    readonly property string gFail: "✗"
    readonly property string gIdle: "·"
    readonly property string gInfo: "󰋽"
    readonly property string gAlert: "󰀦"
    readonly property string gCritical: "󰀪"
    readonly property string gBuilding: "󱥸"
    readonly property string gSpinner: "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    readonly property string gEngine: "󰒋"
    readonly property string gComms: "󰭹"
    readonly property string gResearch: "󰂽"
    readonly property string gControl: "󰕮"
    readonly property string gStream: "󰕧"
    readonly property string gStreaming: "󰕧"
    readonly property string gMonitoring: "󰓅"
    readonly property string gGaming: "󰊴"
    readonly property string gCoding: "󰨸"
    readonly property string gBrowser: "󰈹"
    readonly property string gMedia: "󰎆"
    readonly property string gNet: "󰛳"
    readonly property string gAi: "󰚩"
    readonly property string gAgenda: "󰃭"
    readonly property string gClock: "󰥔"
    readonly property string gCpu: "󰻠"
    readonly property string gMem: "󰍛"
    readonly property string gTemp: "󰔏"
    readonly property string gDisk: "󰋊"
    readonly property string gNetDown: "󰇚"
    readonly property string gNetUp: "󰕒"
    readonly property string gMic: "󰍬"
    readonly property string gMute: "󰍭"
    readonly property string gRec: "⏺"
    readonly property string gLive: "󰐰"
    readonly property string gGpu: "󰢮"
    readonly property string gBattery: "󰁹"
    readonly property string gBell: "󰂚"
    readonly property string gMail: "󰇮"
    readonly property string gVpn: "󰦝"
    readonly property string gLock: "󰌾"
    readonly property string gGit: "󰊢"
    readonly property string gPomo: "󰔛"
    readonly property string gSpend: "󰉁"
    readonly property string gPlay: "󰐊"
    readonly property string gPause: "󰏤"
    readonly property string gSpeaker: "󰕾"
    readonly property string gFirewall: "󰞀"
    readonly property string gWarden: "󰒃"
    readonly property string gRoute: "󰑪"
    readonly property string gRust: "🦀"

    // ---- geometry ([geom]) ----
    readonly property int unit: 4
    readonly property int gap: 8
    readonly property int gapLg: 16
    readonly property int gapXl: 24
    readonly property int barHeight: 40
    readonly property int barHeightCompact: 32
    readonly property int chipHeight: 32
    readonly property int barReserve: 56
    readonly property int padY: 2
    readonly property int padX: 12
    readonly property int padXLg: 16
    readonly property int radiusSm: 4
    readonly property int radius: 6
    readonly property int radiusLg: 12
    readonly property int radiusWindow: 14
    readonly property int border: 2
    readonly property int borderLg: 4

    // ---- motion ([motion]) ----
    readonly property int quickMs: 120
    readonly property int normalMs: 200
    readonly property int slowMs: 380
    readonly property int pulseMs: 2400
    readonly property int liftMs: 120
    readonly property var ease: [0.2, 0.8, 0.2, 1.0, 1, 1]

    // ---- opacity ([opacity]) — 'op' prefixed (overlay clashes [color]) ----
    readonly property real opWindowFocused: 0.85
    readonly property real opWindowUnfocused: 0.85
    readonly property real opWindowFloating: 0.88
    readonly property real opGhosttyBg: 0.88
    readonly property real opGhosttyInactive: 0.78
    readonly property real opOverlay: 0.85
    readonly property real opLauncher: 0.88
    readonly property real opOverviewBackdrop: 0.92

    // ---- blur ([blur]) ----
    readonly property real backdropMd: 12
    readonly property real backdropLg: 20
    readonly property real passes: 2
    readonly property real offset: 3
    readonly property real noise: 0.02
    readonly property real saturation: 1.2

    // ---- glass ([glass]) — Liquid Glass material knobs ----
    readonly property string glassQuality: "high"
    readonly property real glassRefractionPx: 2
    readonly property real glassRimWidth: 1.0
    readonly property real glassRimOpacity: 0.14
    readonly property real glassSpecularIntensity: 0.0
    readonly property real glassSpecularSpeed: 0.0
    readonly property real glassChromaticPx: 0.0
    readonly property real glassAmbientBleed: 0.1
    readonly property real glassTintOpacity: 0.85
    readonly property real glassCornerContinuous: 1
    readonly property real glassNoise: 0.02
    readonly property real glassReduceTransparency: 0
    readonly property real glassReduceMotion: 0
    readonly property real glassContrastFloor: 4.5
    readonly property real glassFocalRefractionPx: 9
    readonly property real glassFocalRimOpacity: 0.22
    readonly property real glassFocalSpecularIntensity: 0.38
    readonly property real glassFocalSpecularSpeed: 0.6
    readonly property real glassFocalChromaticPx: 1.4
    readonly property real glassFocalAmbientBleed: 0.14

    // ---- per-workspace glass quality ([glass.per_workspace]) ----
    function glassQualityFor(ws) {
        switch (ws) {
        case "coding": return "medium";
        case "research": return "medium";
        case "engine": return "low";
        case "browser": return "medium";
        case "monitoring": return "medium";
        case "streaming": return "low";
        case "gaming": return "low";
        case "media": return "low";
        default: return glassQuality;
        }
    }

    // ---- semantic role tier ([semantic]) — bind to ROLES, not hues ----
    readonly property color semBgPrimary: "#1E1E1E"
    readonly property color semBgSecondary: "#2B2B2B"
    readonly property color semBgTertiary: "#3A3A3A"
    readonly property color semBgDanger: "#3A2222"
    readonly property color semTextPrimary: "#F7F6F2"
    readonly property color semTextSecondary: "#B8A789"
    readonly property color semTextTertiary: "#8A8175"
    readonly property color semTextDanger: "#E58B8B"
    readonly property color semTextInfo: "#8FBEEA"
    readonly property color semBorderTertiary: "#454545"
    readonly property color semBorderInfo: "#64A8E5"

    // ---- cockpit knobs ([cockpit]) ----
    readonly property string workspaceLabelCase: "upper"
    readonly property int pagerDot: 8
    readonly property int pagerActiveBorder: 2
    readonly property int pillHairline: 1

    // ---- typography ([font]) ----
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int monoSize: 13
    readonly property string display: "Geist Mono"
    readonly property int uiSize: 11
    readonly property int uiSizeSm: 9
    readonly property int uiSizeLg: 14
    readonly property int headingMd: 16
    readonly property int displayLg: 24
    readonly property int weightDim: 300
    readonly property int weightMetric: 400
    readonly property int weightEmphasis: 500
    readonly property int weightLabel: 600
    readonly property int weightActive: 700

    // ---- brand identity map (workspace/HUD name → colour) ----
    function brand(name) {
        switch (name) {
        case "coding": return coding;
        case "research": return research;
        case "engine": return engine;
        case "browser": return browser;
        case "monitoring": return monitoring;
        case "streaming": return streaming;
        case "gaming": return gaming;
        case "media": return media;
        case "net": return net;
        case "ai": return ai;
        case "agenda": return agenda;
        default: return fgMuted;
        }
    }

    function glyph(name) {
        switch (name) {
        case "coding": return gCoding;
        case "research": return gResearch;
        case "engine": return gEngine;
        case "browser": return gBrowser;
        case "monitoring": return gMonitoring;
        case "streaming": return gStreaming;
        case "gaming": return gGaming;
        case "media": return gMedia;
        case "net": return gNet;
        case "ai": return gAi;
        case "agenda": return gAgenda;
        default: return gIdle;
        }
    }

    function workspaceLabel(s) {
        if (!s) return s;
        switch (workspaceLabelCase) {
        case "upper": return s.toUpperCase();
        case "lower": return s.toLowerCase();
        case "title":
        case "small_caps": return s.charAt(0).toUpperCase() + s.slice(1);
        default: return s;
        }
    }
}
