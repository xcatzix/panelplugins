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

    readonly property var cfg: plasmoid.configuration
    readonly property string photoFolder: cfg.photoFolder
    readonly property bool usePhotoFolder: photoFolder.length > 0
    readonly property bool usePhotoFolderWhilePlaying: cfg.photoFolderWhilePlaying
    readonly property bool showFolderPhoto: usePhotoFolder && (!player.hasActiveMedia || usePhotoFolderWhilePlaying)
    readonly property bool thumbnailVisible: cfg.fullViewThumbnailVisible
    readonly property bool albumCoverBackground: cfg.fullAlbumCoverAsBackground
    readonly property bool songTextVisible: cfg.fullViewSongTextVisible
    readonly property int songTextAlignment: cfg.fullViewSongTextAlignment
    readonly property bool songTextAboveSelector: cfg.fullViewSongTextPosition === Full.SongAndArtistTextPosition.AbovePlayerSelector
    // Always shown when "Media player selector" is ticked (also with no media / one player).
    readonly property bool playerSelectorVisible: cfg.showPlayerSelector
    readonly property bool fullAlbumCoverRounded: cfg.fullAlbumCoverRounded
    readonly property int albumCoverRadius: cfg.fullAlbumCoverRadius
    readonly property bool hasMedia: player.ready
    // No active media -> the configured no-media text is ALWAYS shown.
    // "Show this text while media is playing" only adds the playing case.
    readonly property bool showCustomText: !player.hasActiveMedia || cfg.showCustomTextWithMedia
    // Region B (HTML / TXT area fed by the API download)
    readonly property bool regionBEnabled: cfg.regionBEnabled
    readonly property int margin: cfg.fullMargin
    // bottom edge of the text area under the media selector; both floating
    // windows are flush with it and open upwards (towards the picture)
    readonly property real anchorBottom: column.y + textGroup.y + textGroup.height
    readonly property bool selectorRowVisible: playerSelectorVisible || regionBEnabled
    readonly property int fixedWidth: 360
    property int photoIndex: 0
    readonly property string selectedPhotoUrl: photoModel.count > 0 ? String(photoModel.get(Math.min(photoIndex, photoModel.count - 1), "fileUrl") || "") : ""
    readonly property string displayedImageUrl: showFolderPhoto && selectedPhotoUrl.length > 0 ? selectedPhotoUrl : String(player.artUrl || "")

    // 0 = square corners ... 100 = fully round
    function pctRadius(pct, w, h) {
        return Math.round(pct / 100 * Math.min(w, h) / 2);
    }

    function togglePopup(popup) {
        if (popup.opened)
            popup.close();
        else if (Date.now() - popup.closedAt > 250)
            popup.open();
    }

    // left click: details window, right click: reload
    function textAreaClicked(button) {
        if (button === Qt.RightButton)
            displayTextProvider.reload();
        else
            togglePopup(fullTextPopup);
    }

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

    // Media selector row. The last button toggles region B.
    Component {
        id: playerSelectorComponent

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            Repeater {
                id: selectorRepeater

                model: root.playerSelectorVisible ? player.mpris2Model : null

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

            // keeps the "choose automatically" star visible when there is no player at all
            PlasmaComponents3.ToolButton {
                visible: root.playerSelectorVisible && selectorRepeater.count === 0
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                display: PlasmaComponents3.AbstractButton.IconOnly
                icon.name: "emblem-favorite"
                icon.height: Kirigami.Units.iconSizes.small
                text: i18nc("@action:button", "Choose player automatically")
                checkable: true
                checked: true
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Item {
                visible: !root.playerSelectorVisible
                Layout.fillWidth: true
            }

            // region B toggle: same kind of (music note) icon as the selector
            PlasmaComponents3.ToolButton {
                visible: root.regionBEnabled
                Layout.fillWidth: false
                display: PlasmaComponents3.AbstractButton.IconOnly
                icon.name: "view-media-track"
                icon.height: Kirigami.Units.iconSizes.small
                text: i18n("Show / hide region B")
                checkable: true
                checked: regionBPopup.opened
                onClicked: root.togglePopup(regionBPopup)
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
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
            Layout.leftMargin: root.margin
            Layout.rightMargin: root.margin
            Layout.topMargin: root.margin
            Layout.bottomMargin: root.margin
            implicitWidth: 300
            width: parent.width - root.margin * 2
            height: width

            Image {
                id: albumArtNormal

                anchors.fill: parent
                source: root.displayedImageUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                layer.enabled: root.fullAlbumCoverRounded && cfg.fullAlbumCoverRadius > 0

                layer.effect: OpacityMask {

                    maskSource: Item {
                        width: albumArtNormal.width
                        height: albumArtNormal.height

                        Rectangle {
                            anchors.fill: parent
                            radius: root.pctRadius(cfg.fullAlbumCoverRadius, albumArtNormal.width, albumArtNormal.height)
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

            // Border that separates the photo from the rest of Full.
            Rectangle {
                id: photoSeparator

                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "#d9fffb"
                radius: root.fullAlbumCoverRounded ? root.pctRadius(cfg.fullAlbumCoverRadius, width, height) : 0
                z: 10
            }

        }

        ColumnLayout {
            id: textGroup

            Layout.fillWidth: true
            spacing: 0

            SongAndArtistText {
                visible: root.songTextVisible && root.hasMedia && !root.showCustomText && root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                textAlignment: root.songTextAlignment
                scrollingSpeed: cfg.fullViewTextScrollingSpeed
                title: player.title
                artists: player.artists
                album: player.album
                textFont: widget.baseFont
                titlePosition: cfg.fullTitlePosition
                artistsPosition: cfg.fullArtistsPosition
                albumPosition: cfg.fullAlbumPosition
                hideAlbumForSingles: cfg.fullHideAlbumForSingles
                scrollingEnabled: widget.expanded
            }

            PlasmaComponents3.Label {
                id: fullTextLabelAbove

                visible: root.showCustomText && root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                horizontalAlignment: root.songTextAlignment
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.AutoText
                text: widget.displayText
                font: widget.baseFont

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => root.textAreaClicked(mouse.button)
                }

            }

            Loader {
                visible: root.selectorRowVisible
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                sourceComponent: playerSelectorComponent
            }

            Rectangle {
                visible: root.selectorRowVisible && (root.songTextVisible || root.showCustomText)
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                height: 1
                color: Kirigami.Theme.separatorColor
            }

            SongAndArtistText {
                visible: root.songTextVisible && root.hasMedia && !root.showCustomText && !root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                textAlignment: root.songTextAlignment
                scrollingSpeed: cfg.fullViewTextScrollingSpeed
                title: player.title
                artists: player.artists
                album: player.album
                textFont: widget.baseFont
                titlePosition: cfg.fullTitlePosition
                artistsPosition: cfg.fullArtistsPosition
                albumPosition: cfg.fullAlbumPosition
                hideAlbumForSingles: cfg.fullHideAlbumForSingles
                scrollingEnabled: widget.expanded
            }

            PlasmaComponents3.Label {
                id: fullTextLabelBelow

                visible: root.showCustomText && !root.songTextAboveSelector
                Layout.fillWidth: true
                Layout.leftMargin: root.margin
                Layout.rightMargin: root.margin
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                horizontalAlignment: root.songTextAlignment
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.AutoText
                text: widget.displayText
                font: widget.baseFont

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => root.textAreaClicked(mouse.button)
                }

            }

        }

    }

    // Details window of the bottom text area. Fixed size (settings), bottom edge flush
    // with the bottom edge of the text area, opens upwards over the picture.
    Controls.Popup {
        id: fullTextPopup

        property double closedAt: 0

        parent: root
        width: cfg.detailsFullWidth ? root.width : Math.min(cfg.detailsWidth, root.width)
        height: Math.min(cfg.detailsHeight, Math.max(40, root.anchorBottom))
        x: Math.round((root.width - width) / 2)
        y: Math.max(0, root.anchorBottom - height)
        padding: cfg.detailsPadding
        modal: false
        focus: false
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        onAboutToShow: regionBPopup.close()
        onClosed: closedAt = Date.now()

        background: Rectangle {
            radius: root.pctRadius(cfg.detailsRadius, width, height)
            color: Kirigami.Theme.backgroundColor
            border.color: cfg.detailsBorderColor
            border.width: cfg.detailsBorderWidth
        }

        contentItem: Item {
            Controls.ScrollView {
                id: fullTextScrollView

                anchors.fill: parent
                clip: true
                contentWidth: availableWidth

                TextEdit {
                    width: fullTextScrollView.availableWidth
                    text: widget.displayText
                    textFormat: TextEdit.AutoText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                    color: Kirigami.Theme.textColor
                    font: widget.baseFont
                    padding: 0
                }

            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: displayTextProvider.reload()
            }

        }

    }

    // Region B window (TXT / HTML from the API). Opened by the B button; same
    // placement rules as the details window. Right-click = download again.
    Controls.Popup {
        id: regionBPopup

        property double closedAt: 0

        parent: root
        width: cfg.regionBFullWidth ? root.width : Math.min(cfg.regionBWidth, root.width)
        height: Math.min(cfg.regionBHeight, Math.max(40, root.anchorBottom))
        x: Math.round((root.width - width) / 2)
        y: Math.max(0, root.anchorBottom - height)
        padding: cfg.regionBPadding
        modal: false
        focus: false
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        onAboutToShow: fullTextPopup.close()
        onClosed: closedAt = Date.now()

        background: Rectangle {
            radius: root.pctRadius(cfg.regionBRadius, width, height)
            color: Kirigami.Theme.backgroundColor
            border.color: cfg.regionBBorderColor
            border.width: cfg.regionBBorderWidth
        }

        contentItem: Item {
            Controls.ScrollView {
                id: regionBScroll

                anchors.fill: parent
                clip: true
                contentWidth: availableWidth

                PlasmaComponents3.Label {
                    width: regionBScroll.availableWidth
                    wrapMode: Text.Wrap
                    textFormat: Text.AutoText
                    font: widget.baseFont
                    text: htmlApi.content.length > 0 ? htmlApi.content : (htmlApi.loading ? i18n("Loading…") : i18n("No data. Set the API URL in the Full View settings."))
                    opacity: htmlApi.content.length > 0 ? 1 : 0.6
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }

            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: htmlApi.reload()
            }

        }

    }

}
