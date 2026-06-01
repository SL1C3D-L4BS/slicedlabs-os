pragma Singleton
import QtQuick
import Quickshell

// CC — open/close state for the right-side Control Center panel (bars/ControlCenter.qml).
// Toggled by the cockpit IpcHandler.control() (cockpitctl control / Mod+Alt+C).
Singleton {
    id: cc
    property bool open: false
    function toggle() { open = !open }
    function show() { open = true }
    function close() { open = false }
}
