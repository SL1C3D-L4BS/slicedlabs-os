import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"
import "../registry.js" as Reg

// ModalLayer — full-screen overlay inspector. Dim + (Niri-)blurred backdrop, a
// centered frosted panel that rises in z (scale+fade), domain tiles springing in.
// Opening a domain sets ~/.cache/waybar-active-tab so the reused guarded scripts
// return data; closing restores the focused workspace.
PanelWindow {
    id: win
    visible: Modals.open
    WlrLayershell.namespace: "cockpit-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    readonly property string domain: Modals.current === "context" ? Niri.focused : Modals.current

    // keys browser data — flattened from generated/keys.json (Mod+Alt+K)
    property var binds: []
    Process {
        id: keysProc
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/cockpit/generated/keys.json"]
        stdout: StdioCollector {
            id: kc
            onStreamFinished: {
                try {
                    var d = JSON.parse(kc.text); var out = []
                    ;(d.tools || []).forEach(function (t) { (t.categories || []).forEach(function (c) { (c.binds || []).forEach(function (b) { out.push({ tool: t.name, key: b.key, desc: b.desc, hue: b.hue || "" }) }) }) })
                    win.binds = out
                } catch (e) { win.binds = [] }
            }
        }
    }

    Connections {
        target: Modals
        function onCurrentChanged() {
            if (!Modals.open || Modals.current === "system" || Modals.current === "keys" || Modals.current === "penalty") Niri.restore()
            else Niri.setActive(win.domain)
            if (Modals.current === "keys") keysProc.running = true
            if (Modals.current === "penalty") Warden.reload()
            if (Modals.open) { popScale.restart(); popFade.restart() }
        }
    }

    // dim backdrop — click to dismiss
    Rectangle {
        anchors.fill: parent
        color: Theme.cssOverlayDim
        MouseArea { anchors.fill: parent; onClicked: Modals.close() }
    }

    // centered panel — Liquid Glass surface
    Item {
        id: panel
        anchors.centerIn: parent
        width: Modals.current === "keys" ? 600 : Modals.current === "penalty" ? 580 : 480
        height: Modals.current === "keys" ? Math.min(660, (win.screen ? win.screen.height : 1080) - 80)
                                          : col.implicitHeight + Theme.gapXl * 2
        // entrance animations (fire on open via Connections above)
        NumberAnimation { id: popScale; target: panel; property: "scale"; from: 0.93; to: 1.0; duration: Theme.slowMs; easing.type: Easing.OutCubic }
        NumberAnimation { id: popFade; target: panel; property: "opacity"; from: 0.0; to: 1.0; duration: Theme.normalMs }

        Glass { anchors.fill: parent; radius: Theme.radiusLg; tint: Theme.cssChip; focal: true }
        // swallow clicks on the panel (don't dismiss)
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors.centerIn: parent
            width: parent.width - Theme.gapXl * 2
            spacing: Theme.gap

            // header (penalty box → shield + "N clean · M benched" summary)
            Item {
                width: col.width
                implicitHeight: hdr.implicitHeight
                Row {
                    id: hdr
                    spacing: Theme.gap
                    Text { text: Modals.current === "penalty" ? Theme.gWarden : Theme.glyph(win.domain); color: Modals.current === "penalty" ? Theme.semTextSecondary : Theme.brand(win.domain); font.family: Theme.mono; font.pixelSize: Theme.headingMd }
                    Text { text: Modals.current === "penalty" ? "PENALTY BOX" : (win.domain || "").toUpperCase(); color: Theme.fg; font.bold: true; font.family: Theme.mono; font.pixelSize: Theme.headingMd }
                }
                Text {
                    visible: Modals.current === "penalty"
                    anchors.right: parent.right; anchors.verticalCenter: hdr.verticalCenter
                    text: Warden.summary.clean + " clean · " + Warden.benched + " benched"
                    color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSize
                }
            }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

            // domain tiles (script-driven), stacked
            Repeater {
                model: (Modals.current === "system" || Modals.current === "keys") ? [] : Reg.chips(win.domain)
                delegate: ScriptTile {
                    required property var modelData
                    script: modelData
                    interval: 2000
                    width: col.width
                }
            }

            // system / power actions
            Loader { active: Modals.current === "system"; width: col.width; sourceComponent: powerComp }
            // keybindings browser
            Loader { active: Modals.current === "keys"; width: col.width; sourceComponent: keysComp }
            // penalty box — the governance contract
            Loader { active: Modals.current === "penalty"; width: col.width; sourceComponent: penaltyComp }
        }
    }

    Component {
        id: powerComp
        Row {
            spacing: Theme.gap
            property var acts: [
                ["lock", "loginctl lock-session"],
                ["suspend", "systemctl suspend"],
                ["logout", "niri msg action quit"],
                ["reboot", "systemctl reboot"],
                ["shutdown", "systemctl poweroff"]
            ]
            Repeater {
                model: parent.acts
                delegate: Rectangle {
                    required property var modelData
                    width: 86; height: 40; radius: Theme.radius; color: Qt.rgba(1, 1, 1, 0.05)
                    Text { anchors.centerIn: parent; text: modelData[0]; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                    MouseArea { anchors.fill: parent; onClicked: { powerProc.command = ["bash", "-c", modelData[1]]; powerProc.running = true; Modals.close() } }
                }
            }
        }
    }
    Process { id: powerProc }

    // keybindings browser (Mod+Alt+K) — filter + scrollable, hue-tinted keys
    Component {
        id: keysComp
        FocusScope {
            id: kbrowse
            implicitWidth: col.width
            implicitHeight: 520
            property string filter: ""
            Column {
                anchors.fill: parent
                spacing: Theme.gap
                Rectangle {
                    width: parent.width; height: 34; radius: Theme.radius
                    color: Qt.rgba(1, 1, 1, 0.06); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.08)
                    TextInput {
                        id: fin
                        anchors.fill: parent; anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize
                        focus: true; clip: true
                        onTextChanged: kbrowse.filter = text.toLowerCase()
                    }
                    Text {
                        visible: fin.text.length === 0
                        anchors.left: parent.left; anchors.leftMargin: Theme.padX; anchors.verticalCenter: parent.verticalCenter
                        text: "filter keys…"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize
                    }
                }
                Flickable {
                    width: parent.width
                    height: parent.height - 34 - Theme.gap
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: list
                        width: parent.width
                        spacing: 1
                        Repeater {
                            model: win.binds.filter(function (b) {
                                return kbrowse.filter === "" || (b.key + " " + b.desc + " " + b.tool).toLowerCase().indexOf(kbrowse.filter) >= 0
                            })
                            delegate: Rectangle {
                                required property var modelData
                                width: list.width; height: 30; radius: Theme.radiusSm
                                color: Qt.rgba(1, 1, 1, 0.03)
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX; spacing: Theme.gap
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.key; width: 160; elide: Text.ElideRight
                                        color: (modelData.hue && modelData.hue.length > 0) ? modelData.hue : Theme.fg
                                        font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightLabel
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.desc; width: parent.width - 160 - 64 - Theme.gap * 2; elide: Text.ElideRight
                                        color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.tool; width: 64; horizontalAlignment: Text.AlignRight
                                        color: Theme.inactive; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Penalty Box (governance) — actionable rows call the `warden` CLI ----
    Process { id: wardenProc }
    Timer { id: wReload; interval: 500; onTriggered: Warden.reload() }
    function runWarden(action, agent) {
        wardenProc.command = ["warden", action, agent]
        wardenProc.running = true
        wReload.restart()
    }

    Component {
        id: penaltyComp
        Column {
            width: col.width
            spacing: Theme.gap

            Text {
                visible: Warden.benched === 0
                width: parent.width
                text: "✓ All agents clean — no benchings."
                color: Theme.success
                font.family: Theme.mono; font.pixelSize: Theme.uiSize
            }

            Repeater {
                model: Warden.agents.filter(function (a) { return a.status === "suspended" || a.status === "probation" })
                delegate: Rectangle {
                    required property var modelData
                    readonly property color sev: Warden.sevColor(modelData.severity)
                    width: parent.width
                    implicitHeight: card.implicitHeight + Theme.gap * 2
                    radius: Theme.radius
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(sev.r, sev.g, sev.b, 0.30)

                    Row {
                        id: card
                        anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                        spacing: Theme.gap

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36; height: 36; radius: Theme.radius
                            color: Theme.semBgTertiary
                            Text { anchors.centerIn: parent; text: modelData.initials; color: Theme.semTextSecondary; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis }
                        }

                        Column {
                            width: parent.width - 36 - Theme.gap
                            spacing: 3

                            Item {
                                width: parent.width; height: nm.implicitHeight
                                Text { id: nm; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: modelData.name + " · " + modelData.version; color: Theme.semTextPrimary; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis }
                                Rectangle {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    implicitWidth: bdg.implicitWidth + Theme.gap * 2; height: 20; radius: Theme.radiusSm
                                    color: Qt.rgba(Warden.sevColor(modelData.severity).r, Warden.sevColor(modelData.severity).g, Warden.sevColor(modelData.severity).b, 0.18)
                                    Text { id: bdg; anchors.centerIn: parent; text: modelData.status; color: Warden.sevColor(modelData.severity); font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightEmphasis }
                                }
                            }

                            Text {
                                width: parent.width
                                text: modelData.reason || ""
                                color: Theme.semTextSecondary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                                wrapMode: Text.WordWrap
                            }

                            Row {
                                spacing: Theme.gap
                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.evidence_ref || ""; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                // pass-eval — only for probation agents: account a clean run; graduates to clean after N
                                Rectangle {
                                    visible: modelData.status === "probation"
                                    width: ev.implicitWidth + Theme.gap * 2; height: 24; radius: Theme.radiusSm
                                    color: Qt.rgba(Theme.honey.r, Theme.honey.g, Theme.honey.b, eva.containsMouse ? 0.28 : 0.16)
                                    Text { id: ev; anchors.centerIn: parent; text: "pass eval"; color: Theme.honey; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                    MouseArea { id: eva; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.runWarden("run-eval", modelData.id) }
                                }
                                Rectangle {
                                    width: rh.implicitWidth + Theme.gap * 2; height: 24; radius: Theme.radiusSm
                                    color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, rha.containsMouse ? 0.28 : 0.16)
                                    Text { id: rh; anchors.centerIn: parent; text: "rehab"; color: Theme.success; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                    MouseArea { id: rha; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.runWarden("rehab", modelData.id) }
                                }
                                Rectangle {
                                    width: rt.implicitWidth + Theme.gap * 2; height: 24; radius: Theme.radiusSm
                                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, rta.containsMouse ? 0.28 : 0.16)
                                    Text { id: rt; anchors.centerIn: parent; text: "retire"; color: Theme.error; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                    MouseArea { id: rta; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.runWarden("retire", modelData.id) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: Modals.open; onActivated: Modals.close() }
}
