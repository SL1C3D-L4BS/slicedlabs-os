// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell.Io
import "../generated"
import "../services"

// HermesCard — hermes as a card in the modeless stack: a conversation (you · hermes
// bubbles) over a prompt, with /-commands, permission-gated actions, and a status bar. The
// brain is `hermes ask` (owned Gateway LOCAL route — sovereign · offline · free · receipted).
// × closes it (Stack.close); summoned by Mod+Grave. The flagship of the modal language.
StackCard {
    id: bc
    modalId: "hermes"
    title: "hermes"
    glyph: "✦"
    accent: Theme.brand("ai")

    property var turns: []          // completed exchanges [{ q, a }]
    property string pendingQ: ""    // the question currently in flight
    property bool busy: false
    property var pending: null      // a permission request awaiting approval
    property var attachments: []    // attached file paths → hermes --context
    property var historyRows: []    // recent exchanges (hermes history --json)
    property bool showHistory: false

    Process {
        id: ask
        stdout: StdioCollector { id: aout; onStreamFinished: bc.finish(aout.text.trim(), false) }
        stderr: StdioCollector { id: aerr; onStreamFinished: bc.finish(aerr.text.trim(), true) }
    }
    function finish(a, isErr) {
        if (!bc.busy) return                    // the other stream already finalized this turn
        if (isErr && a.length === 0) return     // empty stderr → nothing to report
        bc.turns = bc.turns.concat([{ "q": bc.pendingQ, "a": a.length ? a : "(no answer)" }])
        bc.pendingQ = ""; bc.busy = false
    }
    function send(q) {
        var s = (q || "").trim()
        if (!s.length) return
        if (s.charAt(0) === "/") { bc.slash(s); return }   // /-commands never reach the brain
        if (bc.busy) return                                 // one question at a time
        bc.pendingQ = s; bc.busy = true; bc.pending = null; bc.showHistory = false
        var cmd = ["hermes", "ask"]
        if (bc.attachments.length > 0) cmd.push("--think")   // reading attached files needs the model (slower)
        for (var i = 0; i < bc.attachments.length; i++) { cmd.push("--context"); cmd.push(bc.attachments[i]) }
        cmd.push(s)
        ask.command = cmd; ask.running = true
    }

    Process { id: act }
    function run(cmd) { act.command = ["bash", "-lc", cmd]; act.running = true }
    function approve() { if (bc.pending) { bc.run(bc.pending.cmd); bc.pending = null } }
    function note(q, a) { bc.turns = bc.turns.concat([{ "q": q, "a": a }]) }   // a local (non-LLM) reply

    Process {
        id: histProc
        stdout: StdioCollector { id: hout; onStreamFinished: { try { bc.historyRows = JSON.parse(hout.text) } catch (e) { bc.historyRows = [] } bc.showHistory = true } }
    }
    function loadHistory() { histProc.command = ["hermes", "history", "--json", "30"]; histProc.running = true }

    // /-commands — dispatched locally; an owned gate is permission-gated like any action
    function slash(s) {
        var body = s.slice(1).trim()
        var sp = body.indexOf(" ")
        var cmd = (sp < 0 ? body : body.slice(0, sp)).toLowerCase()
        var arg = sp < 0 ? "" : body.slice(sp + 1).trim()
        if (cmd === "clear") { bc.turns = []; bc.pendingQ = ""; bc.busy = false; bc.pending = null; bc.showHistory = false }
        else if (cmd === "keys") bc.run("cockpitctl system keys")
        else if (cmd === "system" || cmd === "control") bc.run("cockpitctl system")
        else if (cmd === "attach") { if (arg.length) bc.attachments = bc.attachments.concat([arg]); else bc.note(s, "usage: /attach <path>") }
        else if (cmd === "detach") bc.attachments = []
        else if (cmd === "history") bc.loadHistory()
        else if (cmd === "verify") {
            var g = arg.length ? ("verify-" + arg) : "verify-canon"
            bc.pending = { "summary": "hermes wants to run an owned gate", "detail": g, "scope": "read-only · owned verifier", "cmd": g }
        }
        else if (cmd === "help") bc.note("/help", "commands — /clear · /attach <path> · /detach · /history · /keys · /system · /verify [gate] · /help. anything else is asked to the local brain.")
        else bc.note(s, "unknown command — try /help")
    }

    Column {
        width: parent.width
        spacing: Theme.modalGap

        InputBar {
            id: input
            width: parent.width
            placeholder: "ask hermes…  (offline · local · / for commands)"
            onSubmitted: (t) => { bc.send(t); input.text = "" }
            Component.onCompleted: input.focusInput()
        }

        // /-command hint — only while composing a slash command
        Text {
            visible: input.text.charAt(0) === "/"
            width: parent.width
            text: "commands:  /clear · /attach <path> · /detach · /history · /keys · /system · /verify · /help"
            color: Theme.semTextInfo
            font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
        }

        // attachment chips — files passed as --context on the next ask (× removes)
        Flow {
            width: parent.width
            visible: bc.attachments.length > 0
            spacing: Theme.gap
            Repeater {
                model: bc.attachments
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    implicitWidth: arow.implicitWidth + Theme.gap * 2; height: 24; radius: Theme.radiusSm
                    color: Qt.rgba(bc.accent.r, bc.accent.g, bc.accent.b, 0.16)
                    Row {
                        id: arow
                        anchors.centerIn: parent; spacing: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.modelData.split("/").pop(); color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: bc.accent; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: bc.attachments = bc.attachments.filter(function (v, i) { return i !== chip.index }) }
                        }
                    }
                }
            }
        }

        // history picker — recent prompts; click to re-ask (/history)
        Bubble {
            width: parent.width
            visible: bc.showHistory
            Column {
                width: parent.width
                spacing: 4
                Item {
                    width: parent.width; height: hph.implicitHeight
                    Text { id: hph; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "recent — click to re-ask"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: bc.showHistory = false }
                    }
                }
                Repeater {
                    model: bc.historyRows
                    delegate: Rectangle {
                        id: hrow
                        required property var modelData
                        width: parent.width; height: 26; radius: Theme.radiusSm
                        color: hrm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                        Text { anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX; anchors.verticalCenter: parent.verticalCenter; text: hrow.modelData.prompt; elide: Text.ElideRight; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                        MouseArea { id: hrm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bc.showHistory = false; bc.send(hrow.modelData.prompt) } }
                    }
                }
                Text { visible: bc.historyRows.length === 0; width: parent.width; text: "no history yet — ask hermes something."; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            }
        }

        // conversation — you · hermes bubbles; scrolls when long, sticks to the latest
        Flickable {
            id: conv
            visible: bc.turns.length > 0 || bc.busy
            width: parent.width
            height: Math.min(convCol.implicitHeight, 360)
            contentHeight: convCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: convCol
                width: parent.width
                spacing: Theme.modalGap
                onImplicitHeightChanged: conv.contentY = Math.max(0, implicitHeight - conv.height)
                Repeater {
                    model: bc.turns
                    delegate: Column {
                        id: turn
                        required property var modelData
                        width: convCol.width
                        spacing: Theme.modalGap
                        Bubble { width: parent.width; glyph: "›"; text: turn.modelData.q }
                        Bubble { width: parent.width; emphasis: true; accent: bc.accent; glyph: "✦"; text: turn.modelData.a }
                    }
                }
                Bubble { width: parent.width; visible: bc.busy; glyph: "›"; text: bc.pendingQ }
                Bubble { width: parent.width; visible: bc.busy; text: "thinking…" }
            }
        }

        // permission gate — an action awaits explicit approval (→ sl-sandbox → Warden)
        Bubble {
            width: parent.width
            visible: bc.pending !== null
            accent: Theme.semTextInfo
            PermissionModal {
                width: parent.width
                summary: bc.pending ? bc.pending.summary : ""
                detail: bc.pending ? bc.pending.detail : ""
                scope: bc.pending ? bc.pending.scope : ""
                onApproved: bc.approve()
                onDenied: bc.pending = null
            }
        }

        // quick actions
        Row {
            spacing: Theme.gap
            BcPill { glyph: "⌨"; label: "Keys"; accent: bc.accent; onClicked: bc.run("cockpitctl system keys") }
            BcPill { glyph: "⚙"; label: "System"; accent: bc.accent; onClicked: bc.run("cockpitctl system") }
            BcPill {
                glyph: "▶"; label: "verify-canon"; accent: Theme.semTextInfo
                onClicked: bc.pending = { "summary": "hermes wants to run an owned gate", "detail": "verify-canon", "scope": "read-only · owned verifier", "cmd": "verify-canon" }
            }
        }

        // status bar — route (left) · live posture (right)
        Item {
            width: parent.width
            height: route.implicitHeight
            Text {
                id: route
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "✦ local · knows codex · keys · files · state"
                color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
            }
            Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: bc.busy ? "working…" : "✓ offline · local-only"
                color: bc.busy ? bc.accent : Theme.success
                font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
            }
        }
    }

    component BcPill: Item {
        id: ap
        property string glyph: ""
        property string label: ""
        property color accent: Theme.fgMuted
        signal clicked()
        implicitWidth: apr.implicitWidth + Theme.padXLg * 2
        implicitHeight: Theme.modalTabHeight
        Glass { anchors.fill: parent; radius: height / 2; tint: Theme.cssChip; brand: apm.containsMouse ? ap.accent : Theme.fgMuted; focal: false }
        Row {
            id: apr
            anchors.centerIn: parent
            spacing: Theme.gap
            Text { visible: ap.glyph.length > 0; anchors.verticalCenter: parent.verticalCenter; text: ap.glyph; color: ap.accent; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
            Text { anchors.verticalCenter: parent.verticalCenter; text: ap.label; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
        }
        MouseArea { id: apm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ap.clicked() }
    }
}
