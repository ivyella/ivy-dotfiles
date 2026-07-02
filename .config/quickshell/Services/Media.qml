pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property string artUrl: player?.trackArtUrl ?? ""
    property string artist: player?.trackArtist ?? ""
    property bool canNext: player?.canGoNext ?? false
    property bool canPrev: player?.canGoPrevious ?? false
    readonly property bool hasPlayer: player !== null && title !== ""
    property bool isFirefox: player?.identity.toLowerCase().includes("firefox") ?? false
    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    property bool isSpotify: player?.identity.toLowerCase().includes("spotify") ?? false

    // ── State with reactive bindings ────────────────────────────────────────
    property var player: null
    readonly property string preferredPlayer: "spotify"

    // Direct property bindings - no manual copying needed
    property string title: player?.trackTitle ?? ""

    // ── Efficient player resolution ─────────────────────────────────────────
    function findActivePlayer() {
        const players = Mpris.players.values;
        if (players.length === 0)
            return null;

        // Prefer currently playing
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }

        // Prefer Spotify
        const spotify = players.find(p => p.identity.toLowerCase().includes(preferredPlayer));
        if (spotify)
            return spotify;

        // Keep current if still alive
        if (root.player) {
            const stillExists = players.find(p => p.identity === root.player.identity);
            if (stillExists)
                return stillExists;
        }

        return players[0] ?? null;
    }

    function next() {
        if (root.canNext)
            root.player.next();
    }

    function previous() {
        if (root.canPrev)
            root.player.previous();
    }

    function refresh() {
        root.player = findActivePlayer();
    }

    // ── Controls ──────────────────────────────────────────────────────────────
    function togglePlaying() {
        if (root.player)
            root.player.togglePlaying();
    }

    // Only refresh when players change, not on a timer
    Component.onCompleted: root.refresh()

    // ── Efficient update triggers ─────────────────────────────────────────────
    Connections {
        function onValuesChanged() {
            root.refresh();
        }

        target: Mpris.players
    }
}
