import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    property var mpris2Model: Mpris.Mpris2Model {
        readonly property alias preferredSourceIdentities: root.sourceIdentities
        property var preferredPlayersConnections: []

        onRowsInserted: () => updatePlayerIndex(this)
        onRowsRemoved: () => updatePlayerIndex(this)
        onPreferredSourceIdentitiesChanged: () => updatePlayerIndex(this)

        function updatePlayerIndex(model) {
            if (!preferredSourceIdentities) {
                // Choose the multiplex source when no preferred source is set
                model.currentIndex = 0;
                return;
            }

            clearAllPlayersConnections();

            const preferredModels = [];
            const CONTAINER_ROLE = Qt.UserRole + 1;
            for (let i = 1; i < model.rowCount(); i++) {
                const player = model.data(model.index(i, 0), CONTAINER_ROLE);
                if (preferredSourceIdentities.includes(player.identity)) {
                    preferredModels.push({
                        player: player,
                        index: i
                    });
                }
            }

            // If only one preferred players have been setup, directly use it
            if (preferredSourceIdentities.length === 1) {
                if (preferredModels.length > 0) {
                    model.currentIndex = preferredModels[0].index;
                }
                return;
            }

            // In case of multiple preferred players we replicate the multiplexer logic
            // and use the following:
            // 1. the first currently playing player
            // 2. the first opened player
            //
            // Additionally, on each player status change switch to the player:
            // 1. that just started playing if none of the players were playing before
            // 2. that is still playing if the current player was paused
            for (let model of preferredModels) {
                const handler = function () {
                    const rootModel = root.mpris2Model;

                    if (rootModel.currentPlayer?.playbackStatus === Mpris.PlaybackStatus.Playing) {
                        return;
                    }

                    const status = model.player.playbackStatus;
                    if (status === Mpris.PlaybackStatus.Playing) {
                        rootModel.currentIndex = model.index;
                        return;
                    }

                    if (status === Mpris.PlaybackStatus.Paused) {
                        for (let otherModels of preferredModels) {
                            if (otherModels.player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                                rootModel.currentIndex = otherModels.index;
                                return;
                            }
                        }
                    }
                };

                model.player.playbackStatusChanged.connect(handler);
                preferredPlayersConnections.push({
                    player: model.player,
                    handler: handler
                });
            }

            for (let entry of preferredModels) {
                if (entry.player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                    model.currentIndex = entry.index;
                    return;
                }
            }

            if (preferredModels.length > 0) {
                model.currentIndex = preferredModels[0].index;
                return;
            }
        }

        function clearAllPlayersConnections() {
            for (let connection of preferredPlayersConnections) {
                connection.player.playbackStatusChanged.disconnect(connection.handler);
            }
            preferredPlayersConnections = [];
        }
    }

    property var sourceIdentities: null
    readonly property bool ready: {
        if (!mpris2Model.currentPlayer) {
            return false;
        }
        if (sourceIdentities && !sourceIdentities.includes(mpris2Model.currentPlayer.identity)) {
            return false;
        }
        // Chromium-based browsers stay registered on MPRIS even after the media tab
        // is closed, without clearing their metadata. Requiring actual metadata
        // prevents the widget from staying visible in that case.
        return !!(mpris2Model.currentPlayer.track
               || mpris2Model.currentPlayer.artist
               || mpris2Model.currentPlayer.album);
    }

    readonly property string artists: ready ? mpris2Model.currentPlayer.artist : ""
    readonly property string title: ready ? mpris2Model.currentPlayer.track : ""
    readonly property string album: ready ? mpris2Model.currentPlayer.album : ""
    readonly property int playbackStatus: ready ? mpris2Model.currentPlayer.playbackStatus : Mpris.PlaybackStatus.Unknown
    readonly property string artUrl: ready ? mpris2Model.currentPlayer.artUrl : ""
    readonly property string identity: ready ? mpris2Model.currentPlayer.identity : ""

    readonly property bool canRaise: ready ? mpris2Model.currentPlayer.canRaise : false

    function raise() {
        mpris2Model.currentPlayer.Raise();
    }
}
