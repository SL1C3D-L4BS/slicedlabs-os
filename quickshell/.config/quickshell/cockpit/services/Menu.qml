pragma Singleton
import QtQuick
import Quickshell

// Menu — state for the slide-down command menu summoned by the ☰ button in the
// CenterPill (system options · keybindings · appearance · more). A click toggles
// it; MenuDropdown.qml renders + animates it; click-out / Esc dismiss.
Singleton {
    id: root
    property bool open: false
    function toggle() { open = !open }
    function show()   { open = true }
    function close()  { open = false }
}
