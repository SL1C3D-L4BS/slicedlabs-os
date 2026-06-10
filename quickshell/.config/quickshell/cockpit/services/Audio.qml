// SlicedLabs · body · © 2026 SlicedLabs
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// Audio — native PipeWire sink volume/mute + MPRIS now-playing for the cockpit
// media pill + media modal. `var` typing avoids hard type-name coupling to the
// service classes. Source-agnostic: it reflects whatever is actually playing
// (mpd/lofi is the cockpit's local-audio default), so there is always a player
// to show + control.
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    // Active MPRIS player: the one that's Playing, else any with a track, else the
    // first. Each candidate is checked live (never blindly values[0] — a stale/closed
    // player is the source of the old 'ServiceUnknown / Player:Position' warnings).
    readonly property var player: {
        const ps = Mpris.players ? Mpris.players.values : []
        if (!ps || ps.length === 0) return null
        for (let i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].playbackState === MprisPlaybackState.Playing) return ps[i]
        for (let j = 0; j < ps.length; j++)
            if (ps[j] && ps[j].trackTitle) return ps[j]
        return ps[0]
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player ? (player.playbackState === MprisPlaybackState.Playing) : false
    readonly property string nowPlaying: player ? (player.trackTitle || "") : ""
    readonly property string nowArtist: player
        ? (player.trackArtist || (player.trackArtists && player.trackArtists.length ? player.trackArtists.join(", ") : ""))
        : ""
    readonly property string nowAlbum: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property string sourceName: player ? (player.identity || "Media") : ""

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
}
