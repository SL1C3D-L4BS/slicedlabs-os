pragma Singleton
import QtQuick
import Quickshell

// Modals — modal state. `current` is "" (none), a domain name (media/net/ai/
// agenda/system) or "context" (= focused workspace). Toggled via IPC (cockpitctl).
Singleton {
    id: root
    property string current: ""
    readonly property bool open: current !== ""
    function toggle(name) { current = (current === name ? "" : name) }
    function openModal(name) { current = name }
    function close() { current = "" }
}
