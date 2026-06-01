import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// ControlCenter — a sleek, OWNED right-side control panel. Calm Material-3 spirit
// (ref: tripathiji1312 AuroraSurface) on our own cascade: a static Glass surface,
// no per-frame motion, just an event-driven reveal. Reuses the cockpit services
// (Audio / Vitals) + real CLI (wpctl / makoctl / nmcli / bluetoothctl / ...).
// Summoned by CC.toggle() (cockpitctl control · Mod+Alt+C); dismiss click-out / Esc.
PanelWindow {
    id: win
    visible: CC.open || panel.opacity > 0.01
    WlrLayershell.namespace: "cockpit-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: CC.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    Process { id: act }
    function run(cmd) { act.command = ["bash", "-c", cmd]; act.running = true }
    function runClose(cmd) { run(cmd); CC.close() }

    // caffeine: a live idle inhibitor — running == active
    Process { id: caf; command: ["systemd-inhibit", "--what=idle:sleep", "--who=cockpit", "--why=caffeine", "sleep", "infinity"] }

    // state pollers (only while the panel is open)
    property bool wifiOn: false
    property bool btOn: false
    property bool dndOn: false
    property int briPct: 50
    Process {
        id: poll
        command: ["bash", "-c",
            "echo wifi=$(nmcli -t -f WIFI radio 2>/dev/null); " +
            "echo bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off); " +
            "echo dnd=$(makoctl mode 2>/dev/null | grep -q dnd && echo on || echo off); " +
            "echo bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')"]
        stdout: StdioCollector {
            id: pc
            onStreamFinished: {
                const t = pc.text
                win.wifiOn = /wifi=enabled/.test(t)
                win.btOn = /bt=on/.test(t)
                win.dndOn = /dnd=on/.test(t)
                const m = t.match(/bri=(\d+)/); if (m) win.briPct = parseInt(m[1])
            }
        }
    }
    Timer { interval: 2500; running: CC.open; repeat: true; triggeredOnStart: true; onTriggered: poll.running = true }

    // click outside the panel → dismiss
    MouseArea { anchors.fill: parent; onClicked: CC.close() }

    Item {
        id: panel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.gap
        anchors.rightMargin: Theme.gap
        width: 380
        height: Math.min(820, (win.screen ? win.screen.height : 1080) - Theme.gap * 2)

        transformOrigin: Item.TopRight
        scale: CC.open ? 1.0 : 0.97
        opacity: CC.open ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: Theme.normalMs; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.normalMs } }

        Glass { anchors.fill: parent; radius: Theme.radiusLg; tint: Theme.cssChip; focal: true }
        MouseArea { anchors.fill: parent }   // swallow clicks on the panel

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.gapLg
            spacing: Theme.gapLg

            // ── header: clock + power ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 0
                    Text {
                        id: clk
                        text: Qt.formatTime(new Date(), "hh:mm")
                        color: Theme.fg; font.family: Theme.display
                        font.pixelSize: Theme.displayLg; font.weight: Theme.weightActive
                    }
                    Text {
                        text: Qt.formatDate(new Date(), "dddd, MMMM d")
                        color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
                    }
                    Timer { interval: 1000; running: CC.open; repeat: true; onTriggered: clk.text = Qt.formatTime(new Date(), "hh:mm") }
                }
                Item { Layout.fillWidth: true }
                IconBtn { glyph: Theme.gLock; onClicked: win.runClose("loginctl lock-session") }
                IconBtn { glyph: Theme.gFirewall; onClicked: win.runClose("wlogout -p layer-shell") }
            }

            // ── quick toggles ──────────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Theme.gap
                rowSpacing: Theme.gap
                Toggle { glyph: "󰖩"; label: "Wi-Fi"; sub: win.wifiOn ? "On" : "Off"; on: win.wifiOn
                    onClicked: { win.run("nmcli radio wifi " + (win.wifiOn ? "off" : "on")); win.wifiOn = !win.wifiOn } }
                Toggle { glyph: "󰂯"; label: "Bluetooth"; sub: win.btOn ? "On" : "Off"; on: win.btOn
                    onClicked: { win.run("bluetoothctl power " + (win.btOn ? "off" : "on")); win.btOn = !win.btOn } }
                Toggle { glyph: Theme.gBell; label: "Do Not Disturb"; sub: win.dndOn ? "On" : "Off"; on: win.dndOn; accent: Theme.tertiary
                    onClicked: { win.run("makoctl mode " + (win.dndOn ? "-r dnd" : "-a dnd")); win.dndOn = !win.dndOn } }
                Toggle { glyph: "󰅶"; label: "Caffeine"; sub: caf.running ? "Active" : "Off"; on: caf.running; accent: Theme.secondary
                    onClicked: caf.running = !caf.running }
                Toggle { glyph: Theme.light ? "󰖔" : "󰖨"; label: "Theme"; sub: Theme.light ? "Light" : "Dark"; on: Theme.light
                    onClicked: win.run("$HOME/.local/bin/cockpitctl theme toggle") }
                Toggle { glyph: "󰹑"; label: "Screenshot"; sub: "Region"; on: false
                    onClicked: win.runClose("niri msg action screenshot") }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.06) }

            // ── sliders: volume + brightness ───────────────────────────────────
            VSlider { Layout.fillWidth: true; glyph: Audio.muted ? Theme.gMute : Theme.gSpeaker; value: Audio.volume
                onMoved: (v) => win.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + v + "%")
                onIconClicked: win.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") }
            VSlider { Layout.fillWidth: true; glyph: "󰃟"; value: win.briPct
                onMoved: (v) => { win.briPct = v; win.run("brightnessctl set " + v + "%") } }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.06) }

            // ── system stats ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapLg
                Stat { label: "CPU"; pct: Vitals.cpu }
                Stat { label: "RAM"; pct: Vitals.mem }
                Stat { label: "TEMP"; pct: Math.min(100, Vitals.temp); unit: "°" }
            }

            // ── media card ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Theme.radius
                color: Qt.rgba(1, 1, 1, 0.04)
                visible: Audio.nowPlaying.length > 0
                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.gap; spacing: Theme.gap
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { Layout.fillWidth: true; text: Audio.nowPlaying; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: Audio.nowArtist; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight }
                    }
                    IconBtn { glyph: "󰒮"; onClicked: win.run("playerctl previous") }
                    IconBtn { glyph: Theme.gPlay; onClicked: win.run("playerctl play-pause") }
                    IconBtn { glyph: "󰒭"; onClicked: win.run("playerctl next") }
                }
            }

            Item { Layout.fillHeight: true }   // push the power row to the bottom

            // ── power row ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gap
                Repeater {
                    model: [["lock", "loginctl lock-session"], ["suspend", "systemctl suspend"],
                            ["logout", "niri msg action quit"], ["reboot", "systemctl reboot"],
                            ["off", "systemctl poweroff"]]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: Theme.radius
                        color: pm.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
                        Text { anchors.centerIn: parent; text: modelData[0]; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.runClose(modelData[1]) }
                    }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: CC.open; onActivated: CC.close() }

    // ── inline components ──────────────────────────────────────────────────────
    component IconBtn: Rectangle {
        id: ibtn
        property string glyph: ""
        signal clicked()
        implicitWidth: 34; implicitHeight: 34; radius: 17
        color: ibm.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
        Behavior on color { ColorAnimation { duration: Theme.quickMs } }
        Text { anchors.centerIn: parent; text: ibtn.glyph; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
        MouseArea { id: ibm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ibtn.clicked() }
    }

    component Toggle: Rectangle {
        id: tgl
        property string glyph: ""
        property string label: ""
        property string sub: ""
        property bool on: false
        property color accent: Theme.primary
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 54
        radius: Theme.radius
        color: tgl.on ? Qt.rgba(tgl.accent.r, tgl.accent.g, tgl.accent.b, 0.16)
                      : (tgm.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
        Behavior on color { ColorAnimation { duration: Theme.normalMs } }
        RowLayout {
            anchors.fill: parent; anchors.margins: Theme.gap; spacing: Theme.gap
            Text { text: tgl.glyph; color: tgl.on ? tgl.accent : Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { Layout.fillWidth: true; text: tgl.label; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; font.weight: Theme.weightLabel; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: tgl.sub; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; elide: Text.ElideRight }
            }
        }
        MouseArea { id: tgm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tgl.clicked() }
    }

    component VSlider: Item {
        id: sld
        property string glyph: ""
        property int value: 0
        signal moved(int v)
        signal iconClicked()
        implicitHeight: 28
        RowLayout {
            anchors.fill: parent; spacing: Theme.gap
            Text {
                text: sld.glyph; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeLg
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sld.iconClicked() }
            }
            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.10)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, sld.value)) / 100
                    height: parent.height; radius: 3; color: Theme.primary
                }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6
                    function set(mx) { sld.moved(Math.round(Math.max(0, Math.min(1, mx / track.width)) * 100)) }
                    onPressed: (m) => set(m.x)
                    onPositionChanged: (m) => { if (pressed) set(m.x) }
                }
            }
            Text { text: sld.value; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignRight }
        }
    }

    component Stat: ColumnLayout {
        id: stat
        property string label: ""
        property int pct: 0
        property string unit: "%"
        Layout.fillWidth: true
        spacing: 3
        RowLayout {
            Layout.fillWidth: true
            Text { text: stat.label; color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
            Item { Layout.fillWidth: true }
            Text { text: stat.pct + stat.unit; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm }
        }
        Rectangle {
            Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.10)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, stat.pct)) / 100
                height: parent.height; radius: 2.5
                color: stat.pct > 85 ? Theme.error : Theme.primary
            }
        }
    }
}
