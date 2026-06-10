// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../generated"
import "../services"
import "../components"

// ModalStack — the ONE modeless modal host. Anchored top + right, content-sized (so the desktop
// stays clickable everywhere else), NO backdrop, see-through. Renders a Column of the open cards
// snapped under the RightPill; many open at once, stacked, used alongside your work. Summon/close
// via Stack.toggle(id) (cockpitctl → IPC). keyboardFocus OnDemand = focus on click, never a grab.
PanelWindow {
    id: win
    visible: Stack.any
    WlrLayershell.namespace: "cockpit-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Stack.any ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { top: true; right: true }
    margins { top: Theme.barReserve; right: Theme.gap }
    implicitWidth: Theme.modalWidth
    implicitHeight: Math.max(1, col.implicitHeight)
    color: "transparent"
    exclusiveZone: 0

    Column {
        id: col
        width: Theme.modalWidth
        spacing: Theme.modalGap
        Repeater {
            model: Stack.ids
            delegate: Loader {
                required property var modelData
                width: Theme.modalWidth
                sourceComponent: win.cardFor(modelData)
            }
        }
    }

    function cardFor(id) {
        switch (id) {
        case "hermes": return hermesCard
        case "system": return systemCard
        case "inspector": return inspectorCard
        default: return emptyCard
        }
    }
    Component { id: hermesCard; HermesCard {} }
    Component { id: systemCard; SystemCard {} }
    Component { id: inspectorCard; Inspector {} }
    Component { id: emptyCard; Item { implicitHeight: 0 } }

    Shortcut { sequence: "Escape"; enabled: Stack.any; onActivated: Stack.closeAll() }
}
