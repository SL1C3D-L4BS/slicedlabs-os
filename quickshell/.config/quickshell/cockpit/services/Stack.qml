// SlicedLabs · body · © 2026 SlicedLabs
pragma Singleton
import QtQuick
import Quickshell

// Stack — the modeless modal stack state. An ORDERED set of open modal ids, snapped under the
// RightPill and stacked by the ModalStack host. Many open at once; used alongside the system (no
// screen dim, no input grab). Replaces the one-at-a-time Modals/CC/Menu/Hermes singletons.
// Toggled via IPC (cockpitctl <verb> → qs ipc call cockpit …).
Singleton {
    id: root
    property var ids: []                                  // ordered, e.g. ["hermes","bt"]
    readonly property bool any: ids.length > 0
    function has(id) { return ids.indexOf(id) >= 0 }
    function show(id) { if (!has(id)) ids = ids.concat([id]) }
    function close(id) { ids = ids.filter(function (x) { return x !== id }) }
    function toggle(id) { if (has(id)) close(id); else ids = ids.concat([id]) }
    function closeAll() { ids = [] }

    // SystemCard tab targeting — a pill segment opens System straight to its tab
    // (Controls 0 · Bluetooth 1 · Media 2 · Keys 3 · Governance 4 · Power 5). The signal
    // re-targets a card that's already open; the systemTab seeds a freshly-created one.
    property int systemTab: 0
    signal systemTabRequested(int t)
    function openSystem(t) { systemTab = t; systemTabRequested(t); show("system") }
    function toggleSystem(t) { if (has("system")) close("system"); else openSystem(t) }
    function openSystemNamed(name) {
        var m = { "controls": 0, "bluetooth": 1, "media": 2, "keys": 3, "governance": 4, "power": 5 }
        openSystem(m[name] !== undefined ? m[name] : 0)
    }

    // Inspector — the read-only HUD inspector (Context · Net · AI · Agenda), modeless + tabbed.
    property int inspectorTab: 0
    signal inspectorTabRequested(int t)
    function openInspector(t) { inspectorTab = t; inspectorTabRequested(t); show("inspector") }
    function toggleInspector(t) { if (has("inspector")) close("inspector"); else openInspector(t) }
    function openInspectorNamed(name) {
        var m = { "context": 0, "net": 1, "ai": 2, "agenda": 3 }
        openInspector(m[name] !== undefined ? m[name] : 0)
    }
}
