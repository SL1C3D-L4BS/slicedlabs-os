// SlicedLabs · body · © 2026 SlicedLabs
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Market — the SlicedLabs Marketplace state: the owned catalog (baked from system/marketplace.toml
// by render-marketplace → generated/marketplace.json) + the left panel's open/close. INDEPENDENT of
// the right-side Stack — the Marketplace is its own left-anchored surface, the layer a SlicedLabsOS
// user pulls from. Summoned by the LeftPill glyph, `cockpitctl market`, or the System menu pill.
Singleton {
    id: root
    property bool open: false
    property var items: []
    property var categories: []
    property int count: 0
    property int installedCount: 0

    function toggle() { open = !open }
    function show() { open = true; reload() }
    function close() { open = false }

    Process {
        id: rd
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/cockpit/generated/marketplace.json"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                try {
                    var d = JSON.parse(out.text)
                    root.items = d.items || []
                    root.categories = d.categories || []
                    root.count = d.count || root.items.length
                    root.installedCount = d.installed || 0
                } catch (e) { /* keep the last good catalog */ }
            }
        }
    }
    function reload() { rd.running = true }
    Component.onCompleted: reload()
}
