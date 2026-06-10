// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import Quickshell.Io
import "../generated"
import "../services"
import "../registry.js" as Reg

// Inspector — the consolidated read-only HUD inspector: the modeless successor to the old
// ModalLayer domains. Tabs: Context (the focused workspace) · Net · AI · Agenda. Each renders
// the reused chip scripts (registry.js → ScriptTile) for its domain; tiles hide when their
// script is empty. Writes ~/.cache/cockpit-active-tab so the guarded scripts return data.
// × closes (Stack.close); no screen dim. Tab-targeted via Stack.openInspector(n).
StackCard {
    id: insp
    modalId: "inspector"
    title: "Inspector"
    glyph: Theme.gInfo
    // the card wears the LIVE domain's identity hue (workspace brand on the
    // Context tab; net/ai/agenda HUD hues on theirs) — Liquid Retina v3
    accent: Theme.brand(insp.domainAt(insp.tab))
    property int tab: Stack.inspectorTab
    readonly property var domains: ["context", "net", "ai", "agenda"]
    function domainAt(i) { return insp.domains[i] === "context" ? Niri.focused : insp.domains[i] }
    Behavior on accent { ColorAnimation { duration: Theme.normalMs } }

    // the active-tab cache lets the reused chip scripts know which domain is live
    Process { id: tabset }
    function setActive(d) { tabset.command = ["bash", "-c", "echo " + d + " > \"${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab\""]; tabset.running = true }
    onTabChanged: insp.setActive(insp.domainAt(insp.tab))
    Component.onCompleted: insp.setActive(insp.domainAt(insp.tab))
    Connections { target: Stack; function onInspectorTabRequested(t) { insp.tab = t } }

    Column {
        width: parent.width
        spacing: Theme.modalGap

        TabStrip {
            width: parent.width
            current: insp.tab
            accent: insp.accent
            tabs: [ { "label": "Context", "glyph": Theme.gCoding }, { "label": "Net", "glyph": Theme.gNet }, { "label": "AI", "glyph": Theme.gAi }, { "label": "Agenda", "glyph": Theme.gAgenda } ]
            onSelected: (i) => insp.tab = i
        }

        Text {
            width: parent.width
            text: insp.domains[insp.tab] === "context" ? ("workspace · " + (Niri.focused || "—")) : insp.domains[insp.tab]
            color: insp.accent; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
        }

        // chips for the active domain — full-width stacked tiles (each hides when empty)
        Column {
            id: chips
            width: parent.width
            spacing: Theme.gap
            Repeater {
                model: Reg.chips(insp.domainAt(insp.tab))
                delegate: ScriptTile {
                    required property var modelData
                    script: modelData
                    interval: 2500
                    width: chips.width
                }
            }
        }

        Text {
            width: parent.width
            visible: Reg.chips(insp.domainAt(insp.tab)).length === 0
            text: "nothing wired for this domain yet."
            color: Theme.fgMuted; font.family: Theme.mono; font.pixelSize: Theme.uiSize
        }
    }
}
