pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Niri service — the cockpit's compositor link. Parses `niri msg event-stream`
// for workspaces + focused window, and writes ~/.cache/waybar-active-tab so the
// reused (guarded) chip scripts keep working. Replaces waybar-tab-watcher.
Singleton {
    id: root

    property var workspaces: []          // [{id,name,idx,focused,output,urgent}]
    property string focused: ""          // focused workspace name (brand key)
    property var _wins: ({})             // id → title
    property var _winWs: ({})            // id → workspace_id (per-workspace counts)
    property int _focusedWin: -1
    readonly property string activeWindow:
        (_focusedWin >= 0 && _wins[_focusedWin]) ? _wins[_focusedWin] : ""

    Process {
        id: ev
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser { onRead: (line) => root._ev(line) }
    }

    function _ev(line) {
        var e
        try { e = JSON.parse(line) } catch (_) { return }
        if (e.WorkspacesChanged) _ws(e.WorkspacesChanged.workspaces)
        else if (e.WorkspaceActivated) _act(e.WorkspaceActivated)
        else if (e.WindowsChanged) _winsAll(e.WindowsChanged.windows)
        else if (e.WindowOpenedOrChanged) _win(e.WindowOpenedOrChanged.window)
        else if (e.WindowFocusChanged) root._focusedWin =
            (e.WindowFocusChanged.id === null ? -1 : e.WindowFocusChanged.id)
        else if (e.WindowClosed) { var m = root._wins; delete m[e.WindowClosed.id]; root._wins = m
            var ww = root._winWs; delete ww[e.WindowClosed.id]; root._winWs = ww }
    }

    function _ws(list) {
        var ws = [], foc = root.focused
        for (var i = 0; i < list.length; i++) {
            var w = list[i]
            ws.push({ id: w.id, name: (w.name || ("ws" + w.idx)), idx: w.idx,
                      focused: !!w.is_focused, output: w.output, urgent: !!w.is_urgent })
            if (w.is_focused && w.name) foc = w.name
        }
        root.workspaces = ws
        if (foc && foc !== root.focused) { root.focused = foc; setActive(foc) }
    }

    function _act(a) {
        var ws = root.workspaces.slice(), foc = root.focused
        for (var i = 0; i < ws.length; i++) {
            ws[i].focused = (ws[i].id === a.id)
            if (ws[i].id === a.id && ws[i].name && ws[i].name.indexOf("ws") !== 0) foc = ws[i].name
        }
        root.workspaces = ws
        if (foc !== root.focused) { root.focused = foc; setActive(foc) }
    }

    function _winsAll(list) {
        var m = {}, ww = {}, f = root._focusedWin
        for (var i = 0; i < list.length; i++) {
            m[list[i].id] = list[i].title || ""
            ww[list[i].id] = list[i].workspace_id
            if (list[i].is_focused) f = list[i].id
        }
        root._wins = m; root._winWs = ww; root._focusedWin = f
    }
    function _win(w) {
        var m = root._wins; m[w.id] = w.title || ""; root._wins = m
        var ww = root._winWs; ww[w.id] = w.workspace_id; root._winWs = ww
        if (w.is_focused) root._focusedWin = w.id
    }

    // ---- active-tab state file (drives the reused guarded chip scripts) ----
    Process { id: writer }
    function setActive(name) {
        writer.command = ["bash", "-c",
            "printf %s '" + name + "' > \"${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab\""]
        writer.running = true
    }
    function restore() { setActive(root.focused) }

    // ---- per-workspace window count (drives the pager badge) ----
    function windowCount(wsId) {
        var n = 0, ww = root._winWs
        for (var k in ww) if (ww[k] === wsId) n++
        return n
    }

    // ---- click-to-focus from the pager ----
    Process { id: focuser }
    function focusWorkspace(name) {
        focuser.command = ["niri", "msg", "action", "focus-workspace", name]
        focuser.running = true
    }
}
