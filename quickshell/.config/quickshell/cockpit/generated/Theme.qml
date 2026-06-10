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
    readonly property color coding: "#308BDD"
    readonly property color research: "#976BDA"
    readonly property color engine: "#CA691F"
    readonly property color browser: "#279B89"
    readonly property color monitoring: "#419F39"
    readonly property color streaming: "#CE5495"
    readonly property color gaming: "#E24B49"
    readonly property color media: "#A4821F"
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

    // ---- family accents ([family]) — Liquid Retina v3 half-spokes ----
    readonly property color lavender: "#6C7BE8"
    readonly property color orchid: "#BC5DB6"
    readonly property color jade: "#3D9C6F"
    readonly property color lime: "#7E9136"
    readonly property color tangerine: "#D36035"
    readonly property color gold: "#9A8636"

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
    readonly property string gMarket: "󰟇"
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
    readonly property string gSkipPrev: "󰒮"
    readonly property string gSkipNext: "󰒭"
    readonly property string gSpotify: "󰓇"
    readonly property string gFirewall: "󰞀"
    readonly property string gWarden: "󰒃"
    readonly property string gRoute: "󰑪"
    readonly property string gBluetooth: "󰂯"
    readonly property string gBluetoothOff: "󰂲"
    readonly property string gBluetoothConnected: "󰂱"
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
    readonly property string glassLook: "dark"
    readonly property real glassRefractionPx: 6
    readonly property real glassRimWidth: 1.25
    readonly property real glassRimOpacity: 0.18
    readonly property real glassSpecularIntensity: 0.12
    readonly property real glassSpecularSpeed: 0.0
    readonly property real glassChromaticPx: 0.6
    readonly property real glassAmbientBleed: 0.12
    readonly property real glassTintOpacity: 0.82
    readonly property real glassRimBrandMix: 0.35
    readonly property real glassCornerContinuous: 1
    readonly property real glassNoise: 0.02
    readonly property real glassReduceTransparency: 0
    readonly property real glassReduceMotion: 0
    readonly property real glassContrastFloor: 4.5
    readonly property real glassFocalRefractionPx: 10
    readonly property real glassFocalRimOpacity: 0.22
    readonly property real glassFocalSpecularIntensity: 0.42
    readonly property real glassFocalSpecularSpeed: 0.6
    readonly property real glassFocalChromaticPx: 1.4
    readonly property real glassFocalAmbientBleed: 0.14
    readonly property real glassUltraRefractionPx: 14
    readonly property real glassUltraRimOpacity: 0.3
    readonly property real glassUltraSpecularIntensity: 0.55
    readonly property real glassUltraSpecularSpeed: 0.35
    readonly property real glassUltraChromaticPx: 2.2
    readonly property real glassUltraAmbientBleed: 0.18

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

    // ---- modal design language ([modal]) ----
    readonly property int modalRadius: 16
    readonly property int modalPad: 20
    readonly property int modalGap: 12
    readonly property int modalWidthSm: 520
    readonly property int modalWidth: 640
    readonly property int modalWidthLg: 820
    readonly property real modalMaxHeightFrac: 0.82
    readonly property int modalHeaderHeight: 40
    readonly property int modalTabHeight: 36
    readonly property int modalInputHeight: 42
    readonly property int modalRowHeight: 32
    readonly property real modalEnterScale: 0.96
    readonly property real modalBackdropDim: 0.55
    readonly property real modalHairline: 0.08
    readonly property real modalFillSubtle: 0.04
    readonly property real modalFillHover: 0.12

    // ---- typography ([font]) ----
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int monoSize: 16
    readonly property string display: "Geist Mono"
    readonly property int uiSize: 14
    readonly property int uiSizeSm: 11
    readonly property int uiSizeLg: 18
    readonly property int headingMd: 20
    readonly property int displayLg: 30
    readonly property int weightDim: 300
    readonly property int weightMetric: 400
    readonly property int weightEmphasis: 500
    readonly property int weightLabel: 600
    readonly property int weightActive: 700

    // ---- derived tonal ramps (v3) — lib/color.ramp() at render time ----
    readonly property var rampSteps: ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]
    readonly property var ramps: ({
        "coding": { "50": "#E3F0FF", "100": "#C6E1FE", "200": "#9BC9F8", "300": "#76B3F1", "400": "#53A0EB", "500": "#308BDD", "600": "#186FB7", "700": "#0D5590", "800": "#063964", "900": "#05233E" },
        "research": { "50": "#F1EBFF", "100": "#E3D6FE", "200": "#CDB7F7", "300": "#BA9CF0", "400": "#AA84E9", "500": "#976BDA", "600": "#7A52B5", "700": "#5E3E8E", "800": "#402963", "900": "#27183D" },
        "engine": { "50": "#FFEADE", "100": "#FBD5BF", "200": "#EFB694", "300": "#E59A6C", "400": "#DB8247", "500": "#CA691F", "600": "#A65106", "700": "#803D04", "800": "#592801", "900": "#381701" },
        "browser": { "50": "#DFF4EF", "100": "#C5E6DF", "200": "#9CD1C5", "300": "#76BEAF", "400": "#51AE9D", "500": "#279B89", "600": "#097D6E", "700": "#056054", "800": "#024239", "900": "#022822" },
        "monitoring": { "50": "#E1F5DF", "100": "#C9E8C5", "200": "#A3D49D", "300": "#7FC278", "400": "#60B258", "500": "#419F39", "600": "#2A8023", "700": "#1C6317", "800": "#11440D", "900": "#092907" },
        "streaming": { "50": "#FFE7F1", "100": "#FECFE3", "200": "#F3ACCD", "300": "#E98CB9", "400": "#DF70A8", "500": "#CE5495", "600": "#AA3D78", "700": "#852C5D", "800": "#5C1C3F", "900": "#391026" },
        "gaming": { "50": "#FFE9E6", "100": "#FED2CD", "200": "#FEABA4", "300": "#FA8880", "400": "#F26A64", "500": "#E24B49", "600": "#BB3334", "700": "#922425", "800": "#661617", "900": "#400D0D" },
        "media": { "50": "#F6EEDB", "100": "#E9DDC0", "200": "#D5C294", "300": "#C5AB6C", "400": "#B69748", "500": "#A4821F", "600": "#856707", "700": "#674F04", "800": "#463502", "900": "#2B2001" },
        "primary": { "50": "#E5EFFF", "100": "#CBE0FE", "200": "#A5C6F6", "300": "#84B0EF", "400": "#689CE9", "500": "#2961B1", "600": "#386BB5", "700": "#28528E", "800": "#1A3763", "900": "#0E213D" },
        "secondary": { "50": "#E2F1FF", "100": "#CAE1F8", "200": "#A4C9EB", "300": "#82B3E1", "400": "#65A1D7", "500": "#64A8E5", "600": "#3370A5", "700": "#245681", "800": "#163A59", "900": "#0C2337" },
        "tertiary": { "50": "#FEEBD9", "100": "#F6D8BC", "200": "#E8BA8F", "300": "#DCA064", "400": "#D1893B", "500": "#D9892B", "600": "#995B07", "700": "#764504", "800": "#522E01", "900": "#331B00" },
        "error": { "50": "#FFE9E7", "100": "#FED2CF", "200": "#F8AEAA", "300": "#EF8F8B", "400": "#E67472", "500": "#D95C5C", "600": "#B04143", "700": "#8A3031", "800": "#601F20", "900": "#3C1212" },
        "success": { "50": "#EDF2D5", "100": "#DDE3B5", "200": "#C3CC81", "300": "#ADB74D", "400": "#9AA50F", "500": "#C7D42B", "600": "#6B7307", "700": "#525804", "800": "#383C02", "900": "#212400" },
        "lavender": { "50": "#E9EEFF", "100": "#D4DCFE", "200": "#B3C0FE", "300": "#97A7FA", "400": "#8192F5", "500": "#6C7BE8", "600": "#5460C1", "700": "#3F4997", "800": "#2A316A", "900": "#191D42" },
        "orchid": { "50": "#FDE6FA", "100": "#F5D1F1", "200": "#E6AFE0", "300": "#D991D3", "400": "#CD77C7", "500": "#BC5DB6", "600": "#9A4595", "700": "#783374", "800": "#532150", "900": "#331331" },
        "jade": { "50": "#E1F4E9", "100": "#C9E7D5", "200": "#A2D1B6", "300": "#7EBF9B", "400": "#5EAF85", "500": "#3D9C6F", "600": "#267E56", "700": "#186141", "800": "#0E422B", "900": "#082819" },
        "lime": { "50": "#ECF1DE", "100": "#DAE3C4", "200": "#BECB9C", "300": "#A7B777", "400": "#93A556", "500": "#7E9136", "600": "#647521", "700": "#4C5A15", "800": "#333D0B", "900": "#1F2506" },
        "tangerine": { "50": "#FFE9E2", "100": "#FED3C4", "200": "#F5B29A", "300": "#EC9475", "400": "#E37A54", "500": "#D36035", "600": "#AE4820", "700": "#883514", "800": "#5E230B", "900": "#3B1406" },
        "gold": { "50": "#F3EFDE", "100": "#E5DEC4", "200": "#CFC49B", "300": "#BDAE76", "400": "#AD9B56", "500": "#9A8636", "600": "#7D6B21", "700": "#605215", "800": "#42370C", "900": "#282106" }
    })
    function rampFor(name, step) {
        var r = ramps[name];
        return r ? r[String(step)] : fgMuted;
    }
    function rampOf(name) {
        var r = ramps[name];
        return r ? rampSteps.map(function(s) { return r[s]; }) : [];
    }

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
