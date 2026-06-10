// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell
import Quickshell.Io
import "../generated"
import "../services"

// SystemCard — the ONE consolidated system menu (right module): a modeless tabbed StackCard
// merging the old ☰ menu + Control Center + the inspector domains. Tabs: Controls · Media · Keys ·
// Power (Bluetooth · Governance land next). Rides the live services (Audio · Vitals · Cava · Bt);
// token-driven; one Glass per surface; × closes (Stack.close). No screen dim — modeless.
StackCard {
    id: sys
    modalId: "system"
    title: "System"
    glyph: "⚙"
    accent: Theme.semBorderInfo
    property int tab: Stack.systemTab   // pills open straight to a tab via Stack.openSystem(n)

    Process { id: act }
    function run(cmd) { act.command = ["bash", "-lc", cmd]; act.running = true }
    function runClose(cmd) { run(cmd); Stack.close("system") }
    Process { id: caf; command: ["systemd-inhibit", "--what=idle:sleep", "--who=cockpit", "--why=caffeine", "sleep", "infinity"] }
    Process { id: mediaProc }
    function media(cmd) { mediaProc.command = ["bash", "-c", cmd]; mediaProc.running = true }

    // Bluetooth — the Bt service is native + reactive (Quickshell.Bluetooth); actions call
    // methods directly on the device. A per-action timeout fires a mako toast if a connect/
    // pair stalls (success needs none — the row just updates live).
    Process { id: btToast }
    function btNotify(msg) { btToast.command = ["notify-send", "-a", "Cockpit", "-u", "critical", "Bluetooth", msg]; btToast.running = true }
    property var btPending: null
    Timer {
        id: btWatchTimer; interval: 12000
        onTriggered: {
            if (sys.btPending && !sys.btPending.connected && !sys.btPending.pairing)
                sys.btNotify("Couldn't connect to " + Bt.label(sys.btPending))
            sys.btPending = null
        }
    }
    function btWatch(d) { sys.btPending = d; btWatchTimer.restart() }
    function btIcon(icon) {
        const s = (icon || "").toLowerCase()
        if (s.indexOf("headset") >= 0 || s.indexOf("headphone") >= 0 || s.indexOf("earbud") >= 0) return Theme.gMedia
        if (s.indexOf("audio") >= 0 || s.indexOf("speaker") >= 0 || s.indexOf("sound") >= 0) return Theme.gSpeaker
        if (s.indexOf("gaming") >= 0 || s.indexOf("joypad") >= 0 || s.indexOf("gamepad") >= 0) return Theme.gGaming
        if (s.indexOf("keyboard") >= 0) return Theme.gCoding
        if (s.indexOf("phone") >= 0) return Theme.gComms
        return Theme.gBluetooth
    }

    // Governance / Penalty Box — actionable rows shell out to the `warden` CLI, then reload.
    Process { id: wardenProc }
    Timer { id: wReload; interval: 500; onTriggered: Warden.reload() }
    function runWarden(action, agent) { wardenProc.command = ["warden", action, agent]; wardenProc.running = true; wReload.restart() }

    // keys browser data — flattened from generated/keys.json, loaded when the Keys tab opens
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
                    sys.binds = out
                } catch (e) { sys.binds = [] }
            }
        }
    }
    onTabChanged: {
        if (sys.tab === 3 && sys.binds.length === 0) keysProc.running = true
        Bt.scan(sys.tab === 1)               // auto-scan only while the Bluetooth tab is open (guarded: powered only)
        if (sys.tab === 4) Warden.reload()
    }
    Component.onDestruction: Bt.scan(false)  // never leave discovery running once the card closes
    Connections { target: Stack; function onSystemTabRequested(t) { sys.tab = t } }   // a pill re-targets the tab while already open
    property string keyFilter: ""

    Column {
        width: parent.width
        spacing: Theme.modalGap

        TabStrip {
            width: parent.width
            current: sys.tab
            tabs: [ { "label": "Controls", "glyph": "⚙" }, { "label": "Bluetooth", "glyph": Theme.gBluetooth }, { "label": "Media", "glyph": Theme.gMedia }, { "label": "Keys", "glyph": "⌨" }, { "label": "Governance", "glyph": Theme.gWarden }, { "label": "Power", "glyph": "⏻" } ]
            onSelected: (i) => sys.tab = i
        }

        // ── Controls ──────────────────────────────────────────────────────────
        Column {
            visible: sys.tab === 0
            width: parent.width
            spacing: Theme.modalGap
            Row {
                width: parent.width
                spacing: Theme.gap
                SysToggle { glyph: Theme.light ? "☀" : "☾"; label: "Theme"; sub: Theme.light ? "Light" : "Dark"; on: Theme.light; accent: Theme.honey; onClicked: sys.run("cockpitctl theme toggle") }
                SysToggle { glyph: Theme.gBluetooth; label: "Bluetooth"; sub: Bt.enabled ? (Bt.connectedCount > 0 ? Bt.primaryName : "On") : "Off"; on: Bt.enabled; accent: Theme.net; onClicked: Bt.toggleEnabled() }
                SysToggle { glyph: "☕"; label: "Caffeine"; sub: caf.running ? "Active" : "Off"; on: caf.running; accent: Theme.secondary; onClicked: caf.running = !caf.running }
            }
            Row {
                width: parent.width
                spacing: Theme.gap
                Text { anchors.verticalCenter: parent.verticalCenter; text: Audio.muted ? Theme.gMute : Theme.gSpeaker; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
                Rectangle {
                    id: vtrack
                    width: parent.width - 40 - 44; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, Theme.modalFillHover)
                    Rectangle { width: parent.width * Math.max(0, Math.min(100, Audio.volume)) / 100; height: parent.height; radius: 3; color: sys.accent }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        function setv(mx) { sys.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(Math.max(0, Math.min(1, mx / vtrack.width)) * 100) + "%") }
                        onPressed: (m) => setv(m.x)
                        onPositionChanged: (m) => { if (pressed) setv(m.x) }
                    }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; width: 40; horizontalAlignment: Text.AlignRight; text: Audio.volume + "%"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            }
            Row {
                width: parent.width
                spacing: Theme.gapLg
                SysStat { label: "CPU"; pct: Vitals.cpu }
                SysStat { label: "RAM"; pct: Vitals.mem }
                SysStat { label: "TEMP"; pct: Math.min(100, Vitals.temp); unit: "°" }
            }
            // Marketplace — opens the SlicedLabs layer (the independent left panel)
            Rectangle {
                width: parent.width; height: 44; radius: Theme.radius
                color: mkm.containsMouse ? Qt.rgba(Theme.honey.r, Theme.honey.g, Theme.honey.b, 0.28) : Qt.rgba(Theme.honey.r, Theme.honey.g, Theme.honey.b, 0.15)
                Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                Row {
                    anchors.centerIn: parent; spacing: Theme.gap
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Theme.gMarket; color: Theme.honey; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Open Marketplace"; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                }
                MouseArea { id: mkm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Market.show(); Stack.close("system") } }
            }
        }

        // ── Bluetooth ─────────────────────────────────────────────────────────
        Column {
            visible: sys.tab === 1
            width: parent.width
            spacing: Theme.modalGap

            // adapter — power (left) · scan (right, animated while discovering)
            Item {
                width: parent.width; height: 34
                Rectangle {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    width: pwrR.implicitWidth + Theme.gap * 2; height: 34; radius: Theme.radius
                    color: Bt.enabled ? Qt.rgba(Theme.net.r, Theme.net.g, Theme.net.b, 0.18)
                                      : (pwra.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle))
                    Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                    Row {
                        id: pwrR; anchors.centerIn: parent; spacing: Theme.gap
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Bt.enabled ? Theme.gBluetooth : Theme.gBluetoothOff; color: Bt.enabled ? Theme.net : Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Bt.enabled ? "On" : "Off"; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                    }
                    MouseArea { id: pwra; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Bt.toggleEnabled() }
                }
                Rectangle {
                    visible: Bt.enabled
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: scanR.implicitWidth + Theme.gap * 2; height: 34; radius: Theme.radius
                    color: Bt.discovering ? Qt.rgba(Theme.honey.r, Theme.honey.g, Theme.honey.b, 0.20)
                                          : (scana.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle))
                    Behavior on color { ColorAnimation { duration: Theme.normalMs } }
                    Row {
                        id: scanR; anchors.centerIn: parent; spacing: Theme.gap
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Bt.discovering ? Theme.gSpinner.charAt(spin) : Theme.gRoute
                            color: Bt.discovering ? Theme.honey : Theme.fg
                            font.family: Theme.mono; font.pixelSize: Theme.uiSize
                            property int spin: 0
                            Timer { interval: 90; running: Bt.discovering; repeat: true; onTriggered: parent.spin = (parent.spin + 1) % Theme.gSpinner.length }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Bt.discovering ? "Scanning…" : "Scan"; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
                    }
                    MouseArea { id: scana; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Bt.scan(!Bt.discovering) }
                }
            }

            // empty state
            Text {
                visible: Bt.sorted.length === 0
                width: parent.width
                text: Bt.enabled ? (Bt.discovering ? "Scanning for devices…" : "No devices yet — tap Scan to discover.")
                                 : "Bluetooth is off — toggle it on to see devices."
                color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize; wrapMode: Text.WordWrap
            }

            // device list — connected → paired → available; rows + actions reflect live
            Flickable {
                visible: Bt.sorted.length > 0
                width: parent.width
                height: Math.min(btList.implicitHeight, 320)
                contentHeight: btList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: btList
                    width: parent.width
                    spacing: Theme.gap
                    Repeater {
                        model: Bt.sorted
                        delegate: Rectangle {
                            id: devCard
                            required property var modelData
                            readonly property bool isConn: modelData.connected
                            readonly property bool isPaired: modelData.paired
                            readonly property bool isPairing: modelData.pairing
                            readonly property int batt: Bt.battery(modelData)
                            width: btList.width
                            implicitHeight: drow.implicitHeight + Theme.gap * 2
                            radius: Theme.radius
                            color: isConn ? Qt.rgba(Theme.net.r, Theme.net.g, Theme.net.b, 0.10) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                            border.width: 1
                            border.color: isConn ? Qt.rgba(Theme.net.r, Theme.net.g, Theme.net.b, 0.30) : Qt.rgba(1, 1, 1, Theme.modalHairline)

                            Row {
                                id: drow
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                                spacing: Theme.gap

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter; width: 26
                                    text: sys.btIcon(devCard.modelData.icon); color: devCard.isConn ? Theme.net : Theme.fg
                                    font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: drow.width - 26 - btActions.implicitWidth - Theme.gap * 2
                                    spacing: 2
                                    Text {
                                        width: parent.width; text: Bt.label(devCard.modelData)
                                        color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize
                                        font.weight: Theme.weightEmphasis; elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: (devCard.isPairing ? "Pairing…" : devCard.isConn ? "Connected" : devCard.isPaired ? "Paired" : "Available")
                                              + (devCard.batt >= 0 ? "  ·  " + devCard.batt + "%" : "")
                                        color: devCard.isConn ? Theme.net : Theme.fgMuted
                                        font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight
                                    }
                                }
                                Row {
                                    id: btActions
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.gap
                                    BtAction { visible: !devCard.isPaired && !devCard.isPairing; label: "Pair"; accent: Theme.net; onTriggered: { devCard.modelData.pair(); sys.btWatch(devCard.modelData) } }
                                    BtAction { visible: devCard.isPairing; label: "Cancel"; accent: Theme.honey; onTriggered: devCard.modelData.cancelPair() }
                                    BtAction { visible: devCard.isPaired && !devCard.isConn; label: "Connect"; accent: Theme.success; onTriggered: { devCard.modelData.connect(); sys.btWatch(devCard.modelData) } }
                                    BtAction { visible: devCard.isConn; label: "Disconnect"; accent: Theme.fgMuted; onTriggered: devCard.modelData.disconnect() }
                                    BtAction { visible: devCard.isPaired; label: "Forget"; accent: Theme.error; onTriggered: devCard.modelData.forget() }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Media ─────────────────────────────────────────────────────────────
        Column {
            visible: sys.tab === 2
            width: parent.width
            spacing: Theme.modalGap
            Row {
                width: parent.width
                spacing: Theme.gapLg
                Rectangle {
                    width: 84; height: 84; radius: Theme.radius; color: Theme.semBgTertiary; clip: true
                    Image { anchors.fill: parent; source: Audio.artUrl; visible: Audio.artUrl.length > 0; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true }
                    Text { anchors.centerIn: parent; visible: Audio.artUrl.length === 0; text: Theme.gMedia; color: Theme.semTextSecondary; font.family: Theme.mono; font.pixelSize: Theme.displayLg }
                }
                Column {
                    width: parent.width - 84 - Theme.gapLg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text { width: parent.width; text: Audio.nowPlaying.length > 0 ? Audio.nowPlaying : (Audio.hasPlayer ? "Playing" : "Nothing playing"); color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightActive; elide: Text.ElideRight }
                    Text { visible: Audio.nowArtist.length > 0; width: parent.width; text: Audio.nowArtist; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight }
                    Text { width: parent.width; text: Audio.hasPlayer ? Audio.sourceName : "open the music library"; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight }
                }
            }
            Row {
                id: spectrum
                width: parent.width; height: 40; spacing: 2
                Repeater {
                    model: (Cava.bars && Cava.bars.length) ? Cava.bars.length : 0
                    delegate: Rectangle {
                        required property int index
                        width: Math.max(2, (spectrum.width - (Cava.bars.length - 1) * 2) / Cava.bars.length)
                        anchors.bottom: parent.bottom; radius: 1
                        height: Math.max(2, Math.max(0, Math.min(1, Cava.bars[index] / 100)) * spectrum.height)
                        color: Theme.brand("media")
                        opacity: Audio.isPlaying ? 0.85 : 0.22
                        Behavior on height { NumberAnimation { duration: Theme.quickMs } }
                    }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.gapXl
                Repeater {
                    model: [ { "g": Theme.gSkipPrev, "big": false, "cmd": "cockpitctl media prev" },
                             { "g": Audio.isPlaying ? Theme.gPause : Theme.gPlay, "big": true, "cmd": "cockpitctl media toggle" },
                             { "g": Theme.gSkipNext, "big": false, "cmd": "cockpitctl media next" } ]
                    delegate: Rectangle {
                        required property var modelData
                        width: modelData.big ? 52 : 42; height: width; radius: width / 2
                        color: tbm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                        Text { anchors.centerIn: parent; text: modelData.g; color: Theme.fg; font.family: Theme.mono; font.pixelSize: modelData.big ? Theme.headingMd : Theme.uiSizeLg }
                        MouseArea { id: tbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sys.media(modelData.cmd) }
                    }
                }
            }
        }

        // ── Keys ──────────────────────────────────────────────────────────────
        Column {
            visible: sys.tab === 3
            width: parent.width
            spacing: Theme.modalGap
            Rectangle {
                width: parent.width; height: Theme.modalInputHeight; radius: Theme.radius
                color: Qt.rgba(1, 1, 1, Theme.modalFillSubtle); border.width: 1; border.color: Qt.rgba(1, 1, 1, Theme.modalHairline)
                TextInput {
                    id: kfin
                    anchors.fill: parent; anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                    verticalAlignment: TextInput.AlignVCenter; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize; clip: true
                    onTextChanged: sys.keyFilter = text.toLowerCase()
                }
                Text { visible: kfin.text.length === 0; anchors.left: parent.left; anchors.leftMargin: Theme.padX; anchors.verticalCenter: parent.verticalCenter; text: "filter keys…"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
            }
            Flickable {
                width: parent.width; height: 300; contentHeight: klist.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: klist
                    width: parent.width; spacing: 1
                    Repeater {
                        model: sys.binds.filter(function (b) { return sys.keyFilter === "" || (b.key + " " + b.desc + " " + b.tool).toLowerCase().indexOf(sys.keyFilter) >= 0 })
                        delegate: Rectangle {
                            required property var modelData
                            width: klist.width; height: 30; radius: Theme.radiusSm; color: Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                            Row {
                                anchors.fill: parent; anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX; spacing: Theme.gap
                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.key; width: 150; elide: Text.ElideRight; color: (modelData.hue && modelData.hue.length > 0) ? modelData.hue : Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightLabel }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.desc; width: parent.width - 150 - 60 - Theme.gap * 2; elide: Text.ElideRight; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.tool; width: 60; horizontalAlignment: Text.AlignRight; color: Theme.inactive; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                            }
                        }
                    }
                }
            }
        }

        // ── Power ─────────────────────────────────────────────────────────────
        Row {
            visible: sys.tab === 5
            width: parent.width
            spacing: Theme.gap
            Repeater {
                model: [["lock", "loginctl lock-session"], ["suspend", "systemctl suspend"],
                        ["logout", "niri msg action quit"], ["reboot", "systemctl reboot"],
                        ["off", "systemctl poweroff"]]
                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - Theme.gap * 4) / 5
                    height: 40; radius: Theme.radius
                    color: pm.containsMouse ? Qt.rgba(1, 1, 1, Theme.modalFillHover) : Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                    Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                    Text { anchors.centerIn: parent; text: modelData[0]; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sys.runClose(modelData[1]) }
                }
            }
        }

        // ── Governance ──────────────────────────────────────────────────────────
        Column {
            visible: sys.tab === 4
            width: parent.width
            spacing: Theme.modalGap

            // the Penalty Box contract — clean · benched
            Item {
                width: parent.width; height: govHdr.implicitHeight
                Text { id: govHdr; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Penalty Box"; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightLabel }
                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: Warden.summary.clean + " clean · " + Warden.benched + " benched"; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            }

            Text {
                visible: Warden.benched === 0
                width: parent.width
                text: "✓ All agents clean — no benchings."
                color: Theme.success; font.family: Theme.mono; font.pixelSize: Theme.uiSize
            }

            Flickable {
                visible: Warden.benched > 0
                width: parent.width
                height: Math.min(govList.implicitHeight, 320)
                contentHeight: govList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: govList
                    width: parent.width
                    spacing: Theme.gap
                    Repeater {
                        model: Warden.agents.filter(function (a) { return a.status === "suspended" || a.status === "probation" })
                        delegate: Rectangle {
                            id: gAgent
                            required property var modelData
                            readonly property color sev: Warden.sevColor(modelData.severity)
                            width: govList.width
                            implicitHeight: gcard.implicitHeight + Theme.gap * 2
                            radius: Theme.radius
                            color: Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
                            border.width: 1
                            border.color: Qt.rgba(gAgent.sev.r, gAgent.sev.g, gAgent.sev.b, 0.30)

                            Row {
                                id: gcard
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX
                                spacing: Theme.gap

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 36; height: 36; radius: Theme.radius; color: Theme.semBgTertiary
                                    Text { anchors.centerIn: parent; text: gAgent.modelData.initials; color: Theme.semTextSecondary; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis }
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: gcard.width - 36 - Theme.gap
                                    spacing: 3
                                    Item {
                                        width: parent.width; height: gnm.implicitHeight
                                        Text { id: gnm; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: gAgent.modelData.name + " · " + gAgent.modelData.version; color: Theme.semTextPrimary; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightEmphasis }
                                        Rectangle {
                                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                            implicitWidth: gbdg.implicitWidth + Theme.gap * 2; height: 20; radius: Theme.radiusSm
                                            color: Qt.rgba(gAgent.sev.r, gAgent.sev.g, gAgent.sev.b, 0.18)
                                            Text { id: gbdg; anchors.centerIn: parent; text: gAgent.modelData.status; color: gAgent.sev; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightEmphasis }
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: gAgent.modelData.reason || ""
                                        color: Theme.semTextSecondary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; wrapMode: Text.WordWrap
                                    }
                                    Row {
                                        spacing: Theme.gap
                                        Text { visible: text.length > 0; anchors.verticalCenter: parent.verticalCenter; text: gAgent.modelData.evidence_ref || ""; color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                                        BtAction { visible: gAgent.modelData.status === "probation"; label: "pass eval"; accent: Theme.honey; onTriggered: sys.runWarden("run-eval", gAgent.modelData.id) }
                                        BtAction { label: "rehab"; accent: Theme.success; onTriggered: sys.runWarden("rehab", gAgent.modelData.id) }
                                        BtAction { label: "retire"; accent: Theme.error; onTriggered: sys.runWarden("retire", gAgent.modelData.id) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component BtAction: Rectangle {
        id: ba
        property string label: ""
        property color accent: Theme.fg
        signal triggered()
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        implicitWidth: bal.implicitWidth + Theme.gap * 2; height: 28; radius: Theme.radiusSm
        color: Qt.rgba(ba.accent.r, ba.accent.g, ba.accent.b, bam.containsMouse ? 0.30 : 0.16)
        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
        Text { id: bal; anchors.centerIn: parent; text: ba.label; color: ba.accent; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
        MouseArea { id: bam; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ba.triggered() }
    }

    component SysToggle: Item {
        id: tg
        property string glyph: ""
        property string label: ""
        property string sub: ""
        property bool on: false
        property color accent: Theme.fgMuted
        signal clicked()
        width: (parent.width - Theme.gap * 2) / 3
        implicitHeight: 54
        Glass { anchors.fill: parent; radius: Theme.radius; tint: Theme.cssChip; brand: tg.on ? tg.accent : Theme.fgMuted; focal: false }
        Column {
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.padX; anchors.rightMargin: Theme.padX; spacing: 2
            Text { text: tg.glyph; color: tg.on ? tg.accent : Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
            Text { width: parent.width; text: tg.label; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightLabel; elide: Text.ElideRight }
            Text { width: parent.width; text: tg.sub; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tg.clicked() }
    }

    component SysStat: Item {
        id: st
        property string label: ""
        property int pct: 0
        property string unit: "%"
        width: (parent.width - Theme.gapLg * 2) / 3
        implicitHeight: scol.implicitHeight + 8
        Column {
            id: scol
            width: parent.width; spacing: 3
            Item {
                width: parent.width; height: lab.implicitHeight
                Text { id: lab; anchors.left: parent.left; text: st.label; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                Text { anchors.right: parent.right; text: st.pct + st.unit; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            }
            Rectangle {
                width: parent.width; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, Theme.modalFillHover)
                Rectangle { width: parent.width * Math.max(0, Math.min(100, st.pct)) / 100; height: parent.height; radius: 2.5; color: st.pct > 85 ? Theme.error : Theme.semBorderInfo }
            }
        }
    }
}
