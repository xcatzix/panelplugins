import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: widget

    readonly property int formFactor: Plasmoid.formFactor
    readonly property int location: Plasmoid.location
    readonly property bool showWhenNoMedia: plasmoid.configuration.showWhenNoMedia
    readonly property bool photoFolderSet: plasmoid.configuration.photoFolder.length > 0
    readonly property string displayText: displayTextProvider.text
    readonly property font baseFont: plasmoid.configuration.useCustomFont ? plasmoid.configuration.customFont : Kirigami.Theme.defaultFont

    // NOTE: this stays a pure binding. The old code re-assigned Plasmoid.status
    // from signal handlers, which destroyed the binding.
    Plasmoid.status: (showWhenNoMedia || photoFolderSet || player.ready) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    Plasmoid.backgroundHints: plasmoid.configuration.desktopWidgetBg
    toolTipTextFormat: Text.PlainText
    toolTipMainText: player.hasActiveMedia ? player.title : i18n("No media playing")
    toolTipSubText: {
        if (!player.hasActiveMedia)
            return widget.displayText;
        let text = player.artists ? i18nc("%1 is the media artist/author and %2 is the player name", "by %1 (%2)", player.artists, player.identity) : player.identity;
        text += "\n" + (player.playbackStatus === Mpris.PlaybackStatus.Playing ? i18n("Middle-click to pause") : i18n("Middle-click to play"));
        text += "\n" + (player.canRaise ? i18n("Ctrl+Click to bring player to the front") : i18n("This player can't be raised"));
        return text;
    }

    DisplayTextProvider {
        id: displayTextProvider
    }

    HtmlApiProvider {
        id: htmlApi
    }

    Player {
        id: player

        sourceIdentities: {
            if (!plasmoid.configuration.choosePlayerAutomatically) {
                const identities = plasmoid.configuration.preferredPlayerIdentity;
                return identities ? identities.split(',').filter((x) => {
                    return x;
                }) : null;
            }
            return null;
        }
    }

    LyricsProvider {
        id: lyrics

        title: player.title
        artist: player.artists
        album: player.album
        lengthUs: player.songLength
        positionUs: player.songPosition
        offsetMs: plasmoid.configuration.lyricsOffsetMs
        active: plasmoid.configuration.lyricsEnabled && player.hasActiveMedia
    }

    compactRepresentation: Compact {
    }

    fullRepresentation: Full {
    }

}
