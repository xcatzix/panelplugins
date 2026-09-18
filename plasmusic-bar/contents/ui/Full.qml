import "./components"
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

Item {
    id: root

    enum SongAndArtistTextPosition {
        AbovePlayerSelector,
        UnderPlayerSelector
    }

    readonly property string photoFolder: plasmoid.configuration.photoFolder
    readonly property bool usePhotoFolder: photoFolder.length > 0
    readonly property bool usePhotoFolderWhilePlaying: plasmoid.configuration.photoFolderWhilePlaying
    readonly property bool mediaActive: player.ready && player.playbackStatus !== Mpris.PlaybackStatus.Stopped && player.playbackStatus !== Mpris.PlaybackStatus.Unknown
    readonly property bool showFolderPhoto: usePhotoFolder && (!mediaActive || usePhotoFolderWhilePlaying)
    readonly property bool thumbnailVisible: plasmoid.configuration.fullViewThumbnailVisible
    readonly property bool albumCoverBackground: plasmoid.configuration.fullAlbumCoverAsBackground
    readonly property bool songTextVisible: plasmoid.configuration.fullViewSongTextVisible
    readonly property int songTextAlignment: plasmoid.configuration.fullViewSongTextAlignment
    readonly property bool songTextAboveSelector:
        plasmoid.configuration.fullViewSongTextPosition === Full.SongAndArtistTextPosition.AbovePlayerSelector
    readonly property bool playerSelectorVisible:
        plasmoid.configuration.showPlayerSelector && player.mpris2Model.rowCount() > 2 && player.sourceIdentities == null
    readonly property bool fullAlbumCoverRounded: plasmoid.configuration.fullAlbumCoverRounded
    readonly property int albumCoverRadius: plasmoid.configuration.fullAlbumCoverRadius

    Layout.preferredWidth: column.implicitWidth
    Layout.preferredHeight: column.implicitHeight
    Layout.minimumWidth: column.implicitWidth
    Layout.minimumHeight: column.implicitHeight

    property int photoIndex: 0

    FolderListModel {
        id: photoModel
        folder: root.photoFolder
        showDirs: false
        sortField: FolderListModel.Name
        sortReversed: false
        nameFilters: [
            "*.jpg", "*.jpeg", "*.png", "*.webp",
            "*.gif", "*.bmp", "*.avif", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"
        ]

        onCountChanged: {
            if (photoIndex >= count)
                photoIndex = Math.max(0, count - 1)
        }
    }

    onPhotoFolderChanged: photoIndex = 0

    readonly property string selectedPhotoUrl:
        photoModel.count > 0
        ? String(photoModel.get(Math.min(photoIndex, photoModel.count - 1), "fileUrl") || "")
        : ""

    readonly property string displayedImageUrl:
        showFolderPhoto && selectedPhotoUrl.length > 0 ? selectedPhotoUrl : String(player.artUrl || "")

    // Album-cover/photo colors are only used for the optional desktop background.
    Item {
        visible: albumCoverBackground && thumbnailVisible
        anchors.fill: parent
        z: -1

        Image {
            id: backgroundImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.displayedImageUrl
            opacity: 0.9

            Kirigami.ImageColors {
                id: imageColors
                source: backgroundImage
            }

            LinearGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: imageColors.average }
                    GradientStop { position: 0.7; color: "transparent" }
                    GradientStop { position: 1; color: imageColors.average }
                }
            }
        }
    }

    Component {
        id: playerSelectorComponent

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            Repeater {
                model: player.mpris2Model

                delegate: PlasmaComponents3.ToolButton {
                    required property string iconName
                    required property bool isMultiplexer
                    required property string identity
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    icon.name: iconName
                    icon.height: Kirigami.Units.iconSizes.small
                    text: isMultiplexer ? i18nc("@action:button", "Choose player automatically") : identity
                    checkable: true
                    checked: player.mpris2Model.currentIndex === index
                    onClicked: player.mpris2Model.currentIndex = index

                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        Kirigami.Theme.inherit: true

        // Text and media player selector occupy the former progress-bar area.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            SongAndArtistText {
                visible: root.songTextVisible && root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 5
                textAlignment: root.songTextAlignment
                mediaActive: root.mediaActive
                scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
                title: player.title
                artists: player.artists
                album: player.album
                textFont: baseFont
                titlePosition: plasmoid.configuration.fullTitlePosition
                artistsPosition: plasmoid.configuration.fullArtistsPosition
                albumPosition: plasmoid.configuration.fullAlbumPosition
                hideAlbumForSingles: plasmoid.configuration.fullHideAlbumForSingles
                scrollingEnabled: widget.expanded
            }

            Loader {
                visible: root.playerSelectorVisible
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                sourceComponent: playerSelectorComponent
            }

            Rectangle {
                visible: root.playerSelectorVisible && root.songTextVisible
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                height: 1
                color: Kirigami.Theme.separatorColor
            }

            SongAndArtistText {
                visible: root.songTextVisible && !root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 5
                textAlignment: root.songTextAlignment
                mediaActive: root.mediaActive
                scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
                title: player.title
                artists: player.artists
                album: player.album
                textFont: baseFont
                titlePosition: plasmoid.configuration.fullTitlePosition
                artistsPosition: plasmoid.configuration.fullArtistsPosition
                albumPosition: plasmoid.configuration.fullAlbumPosition
                hideAlbumForSingles: plasmoid.configuration.fullHideAlbumForSingles
                scrollingEnabled: widget.expanded
            }
        }

        // Fixed image area: width and height are explicitly assigned.
        Item {
            id: thumbnailContainer
            visible: root.thumbnailVisible
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            implicitWidth: 300
            width: parent.width - 20
            height: width

            Image {
                id: albumArtNormal
                anchors.fill: parent
                source: root.displayedImageUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true

                layer.enabled: root.fullAlbumCoverRounded && root.albumCoverRadius > 0
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: albumArtNormal.width
                        height: albumArtNormal.height
                        Rectangle {
                            anchors.fill: parent
                            radius: root.albumCoverRadius
                        }
                    }
                }
            }

            PlasmaComponents3.ToolTip {
                id: raisePlayerTooltip
                anchors.centerIn: parent
                text: player.canRaise ? i18n("Bring player to the front") : i18n("This player can't be raised")
                visible: !plasmoid.configuration.hideCanBeRaisedTooltip && coverMouseArea.containsMouse
            }

            MouseArea {
                id: coverMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (player.canRaise)
                        player.raise()
                }
            }

            // Clicking the left/right side changes the selected folder photo.
            MouseArea {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(40, parent.width * 0.22)
                z: 2
                onClicked: {
                    photoIndex = (photoIndex - 1 + photoModel.count) % photoModel.count
                }
            }

            MouseArea {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(40, parent.width * 0.22)
                z: 2
                onClicked: {
                    photoIndex = (photoIndex + 1) % photoModel.count
                }
            }

            PlasmaComponents3.Label {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: i18n("%1 / %2", root.photoIndex + 1, photoModel.count)
                z: 3
            }
        }

    }
}
