pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// Audio — native PipeWire sink volume/mute + MPRIS now-playing (right pill +
// media modal). `var` typing avoids hard type-name coupling to service classes.
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property var player: (Mpris.players && Mpris.players.values.length > 0) ? Mpris.players.values[0] : null
    readonly property string nowPlaying: player ? (player.trackTitle || "") : ""
    readonly property string nowArtist: player ? (player.trackArtist || "") : ""

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
}
