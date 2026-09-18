import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "./components"


PlasmoidItem {
    id: widget

    Plasmoid.status: (showWhenNoMedia || photoFolderSet || player.ready) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    Plasmoid.backgroundHints: plasmoid.configuration.desktopWidgetBg

    readonly property int formFactor: Plasmoid.formFactor
    readonly property int location: Plasmoid.location
    readonly property bool showWhenNoMedia: plasmoid.configuration.showWhenNoMedia
    readonly property bool photoFolderSet: plasmoid.configuration.photoFolder.length > 0
    readonly property string displayText: displayTextProvider.text
    readonly property bool showDisplayTextWithMedia: plasmoid.configuration.showCustomTextWithMedia

    DisplayTextProvider {
        id: displayTextProvider
    }

    readonly property font baseFont: plasmoid.configuration.useCustomFont ? plasmoid.configuration.customFont : Kirigami.Theme.defaultFont

    toolTipTextFormat: Text.PlainText
    toolTipMainText: player.playbackStatus > Mpris.PlaybackStatus.Stopped ? player.title : i18n("No media playing")
    toolTipSubText: {
        let text = player.artists ? i18nc("%1 is the media artist/author and %2 is the player name", "by %1 (%2)", player.artists, player.identity)
            : i18nc("%1 is the player name", "%1", player.identity)
        if (player.canRaise) {
            text += "\n" + i18n("Ctrl+Click to bring player to the front")
        }
        return text
    }

    onShowWhenNoMediaChanged: {
        Plasmoid.status = (showWhenNoMedia || photoFolderSet || player.ready) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    }

    onPhotoFolderSetChanged: {
        Plasmoid.status = (showWhenNoMedia || photoFolderSet || player.ready) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    }

    Player {
        id: player

        sourceIdentities: {
            if (!plasmoid.configuration.choosePlayerAutomatically) {
                const identities = plasmoid.configuration.preferredPlayerIdentity
                return identities ? identities.split(',').filter(x => x) : null
            }
            return null
        }
        onReadyChanged: {
            Plasmoid.status = (showWhenNoMedia || photoFolderSet || player.ready) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
            console.debug(`Player ready changed: ${player.ready} -> plasmoid status changed: ${Plasmoid.status}`)
        }

    }

    compactRepresentation: Compact {}
    fullRepresentation: Full {}
}
