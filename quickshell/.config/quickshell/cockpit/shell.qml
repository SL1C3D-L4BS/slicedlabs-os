import QtQuick
import Quickshell
import Quickshell.Io
import "bars"
import "modals"
import "services"

// The Cockpit — GPU instrument cluster for the [ENGINE] workstation.
// Three floating layer-shell pills on the primary 4K display (DP-2, the Kingston
// panel — this was the HDMI-A-1 connector until the DisplayPort cord swap) over a
// transparent bar; the CENTER hosts the living Reactor. Full-screen inspector modals
// on the overlay layer. Token-driven from generated/Theme.qml (kernel → cockpit →
// engine). IPC: `cockpitctl modal <name>` ⇒ qs ipc call cockpit toggle <name>.
ShellRoot {
    id: root
    // The connector the HUD lives on. If a cable/port swap renames it again, change
    // this ONE string (and the matching niri `output`/`open-on-output` blocks).
    readonly property string primaryOutput: "DP-2"
    readonly property string secondaryOutput: "DP-3"   // monitoring panel: center + right pills only

    // LATCH each screen: resolve reactively, but NEVER fall back to null once we've
    // had it. A transient empty/changed Quickshell.screens (niri reconfigure, output
    // event, a heavy client mapping) would otherwise null every pill's screen and
    // DESTROY the layer surfaces — and quickshell does not reliably re-anchor a
    // PanelWindow when its screen goes null→valid, so the bar stays gone (the
    // "quickshell disappeared" bug). Keeping the last-good screen means the surfaces
    // are never torn down in the first place. (DP-3 has flaky DP link → latch matters.)
    property var primary: null
    property var secondary: null
    function refreshScreens() {
        const ss = Quickshell.screens
        for (let i = 0; i < ss.length; i++) {
            if (ss[i].name === root.primaryOutput)   root.primary = ss[i]
            if (ss[i].name === root.secondaryOutput) root.secondary = ss[i]
        }
        // not found → keep the last-good screen (deliberately do not null either)
    }
    Component.onCompleted: refreshScreens()
    Connections {
        target: Quickshell
        function onScreensChanged() { root.refreshScreens() }
    }

    // Primary (DP-2): the full instrument cluster.
    LeftPill { screen: root.primary }
    CenterPill { screen: root.primary }
    RightPill { screen: root.primary }
    ModalLayer { screen: root.primary }
    MenuDropdown { screen: root.primary }
    ControlCenter { screen: root.primary }

    // Secondary (DP-3, monitoring panel): focal clock + status pill ONLY — no
    // workspaces/left module (that stays unique to the main screen). When DP-3 is
    // absent, root.secondary is null → no surface, so this is inert when unplugged.
    CenterPill { screen: root.secondary }
    RightPill { screen: root.secondary; compact: true }

    IpcHandler {
        target: "cockpit"
        function toggle(name: string): void { Modals.toggle(name) }
        function open(name: string): void { Modals.openModal(name) }
        function close(): void { Modals.close() }
        function status(): string { return Modals.current }
        function menu(): void { Menu.toggle() }
        function control(): void { CC.toggle() }
    }
}
