// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// Marketplace — the SlicedLabs layer, as its own LEFT-anchored surface (the mirror of the
// right-side ModalStack, but independent: it is not in the Stack). A see-through Liquid-Glass
// panel snapped under the LeftPill — browse the owned catalog (Cockpit · hermes · scenes ·
// tooling · design · engine), filter + by category, Open what's installed, Pull what isn't
// (permission-gated → Warden, like hermes's actions). Summoned by the LeftPill ✦ glyph,
// `cockpitctl market`, or the System menu's Marketplace pill. Esc / × closes.
PanelWindow {
    id: win
    visible: Market.open || card.opacity > 0.01
    WlrLayershell.namespace: "cockpit-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Market.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { top: true; left: true }
    margins { top: Theme.barReserve; left: Theme.gap }
    implicitWidth: Theme.modalWidth
    implicitHeight: Math.max(1, card.height)
    color: "transparent"
    exclusiveZone: 0

    readonly property color accent: Theme.honey   // the Marketplace's own gold identity
    property string filter: ""
    property string cat: "All"
    property var pending: null   // an item awaiting pull approval

    Process { id: act }
    function run(cmd) { act.command = ["bash", "-lc", cmd]; act.running = true }
    Process { id: toast }
    function notify(msg) { toast.command = ["notify-send", "-a", "Marketplace", "SlicedLabs Marketplace", msg]; toast.running = true }
    Timer { id: reloadTimer; interval: 5000; onTriggered: Market.reload() }   // reflect a finished pull

    function gly(g) { return (g && Theme[g] !== undefined) ? Theme[g] : (g || "") }
    function trigger(it) {
        if (it.installed) { if (it.cmd && it.cmd.length) win.run(it.cmd); Market.close() }
        else win.pending = it                                   // pull → permission gate
    }
    function confirmPull() {
        var it = win.pending; win.pending = null
        if (!it) return
        win.run("sl-pull " + it.id)                       // the real install → re-bakes the catalog
        win.notify("Pulling “" + it.name + "” — the cockpit updates when it's done.")
        reloadTimer.restart()
    }
    function shown() {
        return Market.items.filter(function (it) {
            var okCat = win.cat === "All" || it.category === win.cat
            var okF = win.filter === "" || (it.name + " " + it.summary + " " + it.category).toLowerCase().indexOf(win.filter) >= 0
            return okCat && okF
        })
    }

    Item {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + Theme.modalPad * 2
        height: implicitHeight
        transformOrigin: Item.TopLeft
        opacity: Market.open ? 1 : 0
        scale: Market.open ? 1 : Theme.modalEnterScale
        Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }
        Behavior on scale { NumberAnimation { duration: Theme.slowMs; easing.type: Easing.OutCubic } }

        Glass { anchors.fill: parent; radius: Theme.modalRadius; tint: Theme.cssChip; brand: win.accent; tier: "focal" }

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: Theme.modalPad
            spacing: Theme.modalGap

            // ── header ──────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: Theme.modalHeaderHeight
                Row {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.gap
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Theme.gMarket; color: win.accent; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text { text: "Marketplace"; color: Theme.fg; font.bold: true; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
                        Text { text: "the SlicedLabs layer — pull tools, scenes, design"; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                    }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26; radius: 13
                    color: xm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                    Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                    Text { anchors.centerIn: parent; text: "✕"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                    MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Market.close() }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, Theme.modalHairline) }

            // ── search ──────────────────────────────────────────────────────────
            InputBar {
                id: search
                width: parent.width
                placeholder: "search the layer…"
                submitOnEnter: false
                onTextChanged: win.filter = text.toLowerCase()
            }

            // ── category chips ──────────────────────────────────────────────────
            Flow {
                width: parent.width
                spacing: Theme.gap
                Repeater {
                    model: ["All"].concat(Market.categories)
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool on: win.cat === chip.modelData
                        implicitWidth: clab.implicitWidth + Theme.padX * 2
                        height: Theme.modalTabHeight - 6
                        radius: height / 2
                        color: chip.on ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.18)
                                       : (cm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle))
                        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                        Text { id: clab; anchors.centerIn: parent; text: chip.modelData; color: chip.on ? win.accent : Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: chip.on ? Theme.weightActive : Theme.weightLabel }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.cat = chip.modelData }
                    }
                }
            }

            // ── catalog ─────────────────────────────────────────────────────────
            Flickable {
                width: parent.width
                height: Math.min(list.implicitHeight, 460)
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.gap
                    Repeater {
                        model: win.shown()
                        delegate: Rectangle {
                            id: it
                            required property var modelData
                            width: list.width
                            implicitHeight: irow.implicitHeight + Theme.gapLg
                            radius: Theme.radius
                            color: irow_hover.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                            border.width: 1
                            border.color: it.modelData.installed ? Qt.rgba(1, 1, 1, Theme.modalHairline) : Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.28)
                            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                            MouseArea { id: irow_hover; anchors.fill: parent; hoverEnabled: true }

                            Row {
                                id: irow
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                                spacing: Theme.gap

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter; width: 30
                                    text: win.gly(it.modelData.glyph)
                                    color: it.modelData.installed ? Theme.fg : win.accent
                                    font.family: Theme.mono; font.pixelSize: Theme.headingMd
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: irow.width - 30 - actBtn.width - Theme.gap * 2
                                    spacing: 2
                                    Row {
                                        spacing: Theme.gap
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: it.modelData.name; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: it.modelData.category + " · v" + it.modelData.version; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                    }
                                    Text { width: parent.width; text: it.modelData.summary; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; wrapMode: Text.WordWrap }
                                }
                                Rectangle {
                                    id: actBtn
                                    anchors.verticalCenter: parent.verticalCenter
                                    readonly property color tone: it.modelData.installed ? Theme.success : win.accent
                                    implicitWidth: ablab.implicitWidth + Theme.gap * 2; height: 30; radius: Theme.radiusSm
                                    color: Qt.rgba(tone.r, tone.g, tone.b, abm.containsMouse ? 0.30 : 0.16)
                                    Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                                    Text { id: ablab; anchors.centerIn: parent; text: it.modelData.installed ? "Open" : "Pull"; color: actBtn.tone; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightEmphasis }
                                    MouseArea { id: abm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.trigger(it.modelData) }
                                }
                            }
                        }
                    }
                    Text {
                        visible: win.shown().length === 0
                        width: list.width
                        text: "nothing matches — clear the filter."
                        color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize
                    }
                }
            }

            // ── pull permission gate ────────────────────────────────────────────
            Item {
                width: parent.width
                visible: win.pending !== null
                implicitHeight: visible ? gate.implicitHeight : 0
                PermissionModal {
                    id: gate
                    width: parent.width
                    summary: win.pending ? ("pull “" + win.pending.name + "” into your system") : ""
                    detail: win.pending ? win.pending.summary : ""
                    scope: "owned layer · permission-gated · receipted → Warden"
                    onApproved: win.confirmPull()
                    onDenied: win.pending = null
                }
            }

            // ── footer ──────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: foot.implicitHeight
                Text { id: foot; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: Theme.gMarket + "  " + Market.count + " in the layer · " + Market.installedCount + " installed"; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "sovereign · owned"; color: Theme.success; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: Market.open; onActivated: Market.close() }
}
