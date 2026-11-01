pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Caelestia.Services

Singleton {
    id: root

    readonly property MprisPlayer player: Players.active
    readonly property bool hasUnknownLength: (player?.length ?? 0) > 2147483647
    readonly property bool lyricsActive: NotchSettings.lyrics && player !== null
    readonly property int lyricIndex: lyricsActive && Lyrics.hasLyrics ? Lyrics.indexForTime(player?.position ?? 0) : -1
    readonly property string currentLine: lyricIndex >= 0 ? (Lyrics.lyrics[lyricIndex] ?? "") : ""
    property int positionUsers

    readonly property var _: {
        const p = root.player;
        if (root.lyricsActive)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
    }

    function lengthStr(length: real): string {
        if (length < 0)
            return "--:--";
        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");
        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    function seekToLine(index: int): void {
        if (player?.canSeek)
            player.position = Lyrics.timeForIndex(index);
    }

    Timer {
        running: (root.player?.isPlaying ?? false) && root.positionUsers > 0
        interval: 250
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }
}
