// SlicedLabs · body · © 2026 SlicedLabs
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bt — native, reactive Bluetooth state for the cockpit (bar glyph · bt modal · CC
// tile). Wraps Quickshell.Bluetooth exactly as Audio.qml wraps Pipewire: no
// bluetoothctl polling/parsing — the adapter + device objects are live, so power,
// discovery, connection, pairing + battery all reflect instantly. `var` typing
// avoids hard coupling to the module's C++ type names. (Named `Bt`, not `Bluetooth`,
// to leave the native singleton un-shadowed.)
Singleton {
    id: root

    // the default adapter (BluetoothAdapter) — null if bluez/adapter is absent
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property string adapterName: adapter ? adapter.name : ""

    // every known device for this adapter (a reactive ObjectModel → JS array)
    readonly property var devices: (Bluetooth.devices ? Bluetooth.devices.values : []).filter(function (d) { return d })

    // a stable display ordering: connected → paired → the rest, then by name.
    readonly property var sorted: {
        const ds = devices.slice()
        ds.sort(function (a, b) {
            const ra = (a.connected ? 0 : (a.paired ? 1 : 2))
            const rb = (b.connected ? 0 : (b.paired ? 1 : 2))
            if (ra !== rb) return ra - rb
            return root.label(a).toLowerCase().localeCompare(root.label(b).toLowerCase())
        })
        return ds
    }

    // connected subset → drives the bar glyph
    readonly property var connected: devices.filter(function (d) { return d.connected })
    readonly property int connectedCount: connected.length
    readonly property var primary: connectedCount > 0 ? connected[0] : null
    readonly property string primaryName: primary ? label(primary) : ""
    // BluetoothDevice.battery is a 0.0–1.0 fraction (valid only when batteryAvailable)
    readonly property int primaryBattery: (primary && primary.batteryAvailable) ? Math.round(primary.battery * 100) : -1

    // human label for a device: prefer the friendly name, fall back to MAC
    function label(d) { return d ? (d.deviceName || d.name || d.address || "device") : "" }
    // battery percent for any device (−1 = unknown)
    function battery(d) { return (d && d.batteryAvailable) ? Math.round(d.battery * 100) : -1 }

    function setEnabled(b) { if (adapter) adapter.enabled = b }
    function toggleEnabled() { if (adapter) adapter.enabled = !adapter.enabled }
    // discovery only makes sense while powered; guard so a stray call is a no-op
    function scan(on) { if (adapter && adapter.enabled) adapter.discovering = on }
}
