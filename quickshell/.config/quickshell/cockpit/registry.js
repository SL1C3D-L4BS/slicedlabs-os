.pragma library
// Tab → chip-script registry (paths relative to ~/.config/waybar/scripts/).
// Mirrors the old Waybar config.jsonc module map — the data plumbing is reused
// verbatim; the cockpit just execs these and renders the JSON they emit.
var TABS = {
    engine:     ["engine/build.sh", "engine/target.sh", "engine/tests.sh"],
    research:   [],
    streaming:  ["stream/obs.sh", "stream/scene.sh", "stream/mic.sh", "stream/bitrate.sh", "stream/uptime.sh"],
    monitoring: ["monitoring/top-cpu.sh", "monitoring/top-mem.sh", "monitoring/disk-pressure.sh", "monitoring/failed-units.sh", "monitoring/net-io.sh"],
    gaming:     ["gaming/status.sh", "gaming/gpu.sh", "gaming/cpu_temp.sh", "gaming/gamemode.sh", "gaming/ds4.sh"],
    coding:     ["tabs/coding/git.sh", "tabs/coding/build.sh", "tabs/coding/team.sh", "tabs/coding/corpus.sh", "tabs/coding/pomo.sh"],
    browser:    ["tabs/browser/status.sh"],
    media:      ["media/now.sh", "media/easyeffects.sh", "media/sink.sh"],
    net:        ["net/vpn.sh", "net/firewall.sh", "net/route.sh", "net/link.sh"],
    ai:         ["ai/spend.sh", "ai/agents.sh", "ai/pomo.sh"],
    agenda:     ["agenda/next.sh", "agenda/standup.sh"]
};
function chips(tab) { return TABS[tab] || []; }
function headline(tab) { return (TABS[tab] || []).slice(0, 3); }
