import "./components"
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

Item {
    id: root

    enum SongAndArtistTextPosition {
        AbovePlayerSelector,
        UnderPlayerSelector
    }

    readonly property string photoFolder: plasmoid.configuration.photoFolder
    readonly property bool usePhotoFolder: photoFolder.length > 0
    readonly property bool usePhotoFolderWhilePlaying: plasmoid.configuration.photoFolderWhilePlaying
    readonly property bool showFolderPhoto: usePhotoFolder && (!player.hasActiveMedia || usePhotoFolderWhilePlaying)
    readonly property bool thumbnailVisible: plasmoid.configuration.fullViewThumbnailVisible
    readonly property bool albumCoverBackground: plasmoid.configuration.fullAlbumCoverAsBackground
    readonly property bool songTextVisible: plasmoid.configuration.fullViewSongTextVisible
    readonly property int songTextAlignment: plasmoid.configuration.fullViewSongTextAlignment
    readonly property bool songTextAboveSelector: plasmoid.configuration.fullViewSongTextPosition === Full.SongAndArtistTextPosition.AbovePlayerSelector
    readonly property bool playerSelectorVisible: plasmoid.configuration.showPlayerSelector && player.mpris2Model.rowCount() > 2 && player.sourceIdentities == null
    readonly property bool fullAlbumCoverRounded: plasmoid.configuration.fullAlbumCoverRounded
    readonly property int albumCoverRadius: plasmoid.configuration.fullAlbumCoverRadius
    readonly property bool hasMedia: player.ready
    // When there is no active media, always show the configured no-media text.
    // The "Show this text while media is playing" option only controls playback state.
    readonly property bool showCustomText: !player.hasActiveMedia || plasmoid.configuration.showCustomTextWithMedia
    readonly property int fixedWidth: 360
    property int photoIndex: 0
    readonly property string selectedPhotoUrl: photoModel.count > 0 ? String(photoModel.get(Math.min(photoIndex, photoModel.count - 1), "fileUrl") || "") : ""
    readonly property string displayedImageUrl: showFolderPhoto && selectedPhotoUrl.length > 0 ? selectedPhotoUrl : String(player.artUrl || "")

    width: fixedWidth
    Layout.preferredWidth: fixedWidth
    Layout.minimumWidth: fixedWidth
    Layout.maximumWidth: fixedWidth
    Layout.preferredHeight: column.implicitHeight
    Layout.minimumHeight: column.implicitHeight
    onPhotoFolderChanged: photoIndex = 0

    FolderListModel {
        id: photoModel

        folder: root.photoFolder
        showDirs: false
        sortField: FolderListModel.Name
        sortReversed: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.avif", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        onCountChanged: {
            if (photoIndex >= count)
                photoIndex = Math.max(0, count - 1);

        }
    }

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
                    GradientStop {
                        position: 0
                        color: imageColors.average
                    }

                    GradientStop {
                        position: 0.7
                        color: "transparent"
                    }

                    GradientStop {
                        position: 1
                        color: imageColors.average
                    }

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

            MouseArea {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(40, parent.width * 0.22)
                z: 2
                onClicked: photoIndex = (photoIndex - 1 + photoModel.count) % photoModel.count
            }

            MouseArea {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(40, parent.width * 0.22)
                z: 2
                onClicked: photoIndex = (photoIndex + 1) % photoModel.count
            }

            PlasmaComponents3.Label {
                visible: root.showFolderPhoto && photoModel.count > 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: i18n("%1 / %2", root.photoIndex + 1, photoModel.count)
                z: 3
            }

            // 照片与 Full 窗口内容之间的分隔边框。
            // 边框跟随照片区域，不再包住整个 Full 窗口。
            Rectangle {
                id: photoSeparator

                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "#d9fffb"
                z: 10
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            SongAndArtistText {
                visible: root.songTextVisible && root.hasMedia && !root.showCustomText && root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                textAlignment: root.songTextAlignment
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

            PlasmaComponents3.Label {
                id: fullTextLabelAbove

                visible: root.showCustomText && root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                horizontalAlignment: root.songTextAlignment
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.AutoText
                text: displayText
                font: baseFont
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
                visible: root.playerSelectorVisible && (root.songTextVisible || root.showCustomText)
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                height: 1
                color: Kirigami.Theme.separatorColor
            }

            SongAndArtistText {
                visible: root.songTextVisible && root.hasMedia && !root.showCustomText && !root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                textAlignment: root.songTextAlignment
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

            PlasmaComponents3.Label {
                id: fullTextLabelBelow

                visible: root.showCustomText && !root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                horizontalAlignment: root.songTextAlignment
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.AutoText
                text: displayText
                font: baseFont
            }

        }

    }

    // Full text popup:
    // - fixed width
    // - its bottom edge is always aligned with the bottom edge of Full
    // - it opens above Full, with a vertical scrollbar when needed
    Controls.Popup {
        id: fullTextPopup

        function reposition() {
            if (!parent)
                return ;

            const bottomLeft = root.mapToItem(parent, 0, root.height);
            // Full 的底边作为 Popup 的底边基准。
            x = bottomLeft.x;
            y = bottomLeft.y - height;
            // Popup 保持 fixed width；如果 Overlay 足够宽，则限制在其中。
            if (parent.width > 0 && parent.width >= width)
                x = Math.max(0, Math.min(x, parent.width - width));

        }

        width: root.fixedWidth
        height: 220
        padding: 12
        modal: false
        focus: false
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        onOpened: reposition()
        onHeightChanged: {
            if (opened)
                reposition();

        }

        Connections {
            function onXChanged() {
                if (fullTextPopup.opened)
                    fullTextPopup.reposition();

            }

            function onYChanged() {
                if (fullTextPopup.opened)
                    fullTextPopup.reposition();

            }

            function onWidthChanged() {
                if (fullTextPopup.opened)
                    fullTextPopup.reposition();

            }

            function onHeightChanged() {
                if (fullTextPopup.opened)
                    fullTextPopup.reposition();

            }

            target: root
        }

        background: Rectangle {
            radius: 8
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
        }

        contentItem: Controls.ScrollView {
            id: fullTextScrollView

            clip: true

            TextEdit {
                id: fullTextEdit

                width: fullTextScrollView.availableWidth
                text: displayText
                textFormat: TextEdit.AutoText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: Kirigami.Theme.textColor
                font: baseFont
                padding: 0
                height: Math.max(implicitHeight, 1)
            }

        }

    }

    // 只让 Full 中实际显示的 plasMtext 文本区域响应点击。
    MouseArea {
        id: fullTextClickArea

        visible: root.showCustomText && (fullTextLabelAbove.visible || fullTextLabelBelow.visible)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: fullTextLabelAbove.visible ? fullTextLabelAbove.top : fullTextLabelBelow.top
        anchors.bottom: fullTextLabelAbove.visible ? fullTextLabelAbove.bottom : fullTextLabelBelow.bottom
        z: 20
        acceptedButtons: Qt.LeftButton
        onClicked: fullTextPopup.open()
    }

}
