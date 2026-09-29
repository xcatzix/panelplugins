import "./components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

Item {
    // Compact is divided into three independent click regions:
    //   1. text      -> text popup
    //   2. soundbars -> no click action
    //   3. icon      -> Full
    // These MouseAreas are above the generic panel MouseArea so the three
    // regions do not trigger the old "toggle Full" behavior.

    id: compact

    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool fillAvailableSpace: plasmoid.configuration.fillAvailableSpace
    readonly property int widgetThickness: horizontal ? height : width
    readonly property int iconSize: Math.round(widgetThickness * plasmoid.configuration.panelIconSizeRatio)
    readonly property int lengthMargin: Math.round((widgetThickness - Math.max(controlsSize, iconSize))) / 2
    readonly property bool colorsFromAlbumCover: plasmoid.configuration.colorsFromAlbumCover
    readonly property int panelBackgroundRadius: plasmoid.configuration.panelBackgroundRadius
    readonly property bool useImageColors: panelIcon.imageReady && panelIcon.type == PanelIcon.Type.Image && colorsFromAlbumCover
    readonly property color imageColor: useImageColors ? panelIcon.imageColor : Kirigami.Theme.textColor
    readonly property color backgroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, "black", 0.5)
    property color backgroundColor: useImageColors ? backgroundColorFromImage : "transparent"
    readonly property var backgroundColorBrightness: Kirigami.ColorUtils.brightnessForColor(backgroundColor)
    readonly property color contrastColor: backgroundColorBrightness === Kirigami.ColorUtils.Dark ? "white" : "#1a1a1a"
    readonly property color foregroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, contrastColor, 0.6)
    property color foregroundColor: useImageColors ? foregroundColorFromImage : Kirigami.Theme.textColor

    Layout.preferredWidth: horizontal ? grid.implicitWidth + lengthMargin * 2 : grid.implicitWidth
    Layout.preferredHeight: !horizontal ? grid.implicitHeight + lengthMargin * 2 : grid.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.fillHeight: horizontal || fillAvailableSpace
    Layout.fillWidth: !horizontal || fillAvailableSpace
    layer.enabled: compact.panelBackgroundRadius > 0 && (!Qt.colorEqual(backgroundColor, "transparent") || plasmoid.configuration.mediaProgressInPanel)

    Rectangle {
        anchors.fill: parent
        color: backgroundColor

        Item {
            width: horizontal ? parent.width : parent.width
            height: horizontal ? parent.height : parent.height

            Rectangle {
                id: progress

                // color: foregroundColor
                color: "#82c7ff"
                height: horizontal ? parent.height : parent.height * (player.songPosition / player.songLength)
                width: horizontal ? parent.width * (player.songPosition / player.songLength) : parent.width
                visible: plasmoid.configuration.mediaProgressInPanel
                opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 0.88 : 0.45
            }

        }

    }

    MouseAreaWithWheelHandler {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        onClicked: (mouse) => {
            if (mouse.modifiers & Qt.ControlModifier) {
                if (player.canRaise)
                    player.raise();

            } else {
                widget.expanded = !widget.expanded;
            }
        }
        onWheelUp: {
            player.changeVolume(plasmoid.configuration.volumeStep / 100, true);
        }
        onWheelDown: {
            player.changeVolume(-plasmoid.configuration.volumeStep / 100, true);
        }
    }

    GridLayout {
        id: grid

        columns: horizontal ? grid.children.length : 1
        rows: horizontal ? 1 : grid.children.length
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing
        anchors.leftMargin: horizontal ? lengthMargin : 0
        anchors.rightMargin: horizontal ? lengthMargin : 0
        anchors.bottomMargin: horizontal ? 0 : lengthMargin
        anchors.topMargin: horizontal ? 0 : lengthMargin
        anchors.fill: parent

        GridLayout {
            id: songGrid

            readonly property int textAlignment: plasmoid.configuration.songTextAlignment
            readonly property int fxdWidth: plasmoid.configuration.songTextFixedWidth + 2 * Kirigami.Units.smallSpacing
            readonly property bool useFixedWidth: plasmoid.configuration.useSongTextFixedWidth
            readonly property int length: horizontal ? width : height

            visible: plasmoid.configuration.songTextInPanel
            columns: horizontal ? songGrid.children.length : 1
            rows: horizontal ? 1 : songGrid.children.length
            Layout.preferredWidth: horizontal && useFixedWidth && !fillAvailableSpace ? fxdWidth : -1
            Layout.preferredHeight: !horizontal && useFixedWidth && !fillAvailableSpace ? fxdWidth : -1
            Layout.fillHeight: horizontal || fillAvailableSpace
            Layout.fillWidth: !horizontal || fillAvailableSpace
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Item {
                readonly property bool fill: [Qt.AlignRight, Qt.AlignCenter].includes(songGrid.textAlignment)

                Layout.fillHeight: !horizontal && fill
                Layout.fillWidth: horizontal && fill
            }

            Item {
                id: songAndArtistTextColumn

                Layout.fillHeight: horizontal
                Layout.fillWidth: !horizontal
                Layout.preferredHeight: !horizontal ? songAndArtistText.width : null
                Layout.preferredWidth: horizontal ? songAndArtistText.width : null
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                SongAndArtistText {
                    id: songAndArtistText

                    anchors.centerIn: parent
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    rotation: {
                        if (horizontal)
                            return 0;

                        if (widget.location === PlasmaCore.Types.LeftEdge)
                            return -90;

                        if (widget.location === PlasmaCore.Types.RightEdge)
                            return 90;

                    }
                    maxWidth: {
                        if (fillAvailableSpace || songGrid.useFixedWidth)
                            return songGrid.length;

                        return plasmoid.configuration.maxSongWidthInPanel;
                    }
                    scrollingBehaviour: plasmoid.configuration.textScrollingBehaviour
                    scrollingSpeed: plasmoid.configuration.textScrollingSpeed
                    scrollingResetOnPause: plasmoid.configuration.textScrollingResetOnPause
                    scrollingEnabled: plasmoid.configuration.textScrollingEnabled
                    titlePosition: plasmoid.configuration.titlePosition
                    artistsPosition: plasmoid.configuration.artistsPosition
                    albumPosition: plasmoid.configuration.albumPosition
                    hideAlbumForSingles: plasmoid.configuration.compactHideAlbumForSingles
                    forcePauseScrolling: {
                        if (!plasmoid.configuration.pauseTextScrollingWhileMediaIsNotPlaying)
                            return false;

                        return player.playbackStatus !== Mpris.PlaybackStatus.Playing;
                    }
                    textFont: baseFont
                    textColor: foregroundColor
                    title: player.title
                    artists: player.artists
                    album: player.album
                    textAlignment: songGrid.textAlignment
                    showSecondLine: false
                    truncateStyle: plasmoid.configuration.compactTruncatedTextStyle
                    opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 1 : 0.75
                }

            }

            Item {
                readonly property bool fill: [Qt.AlignLeft, Qt.AlignCenter].includes(songGrid.textAlignment)

                Layout.fillHeight: !horizontal && fill
                Layout.fillWidth: horizontal && fill
            }

        }

        SoundBars {
            id: soundBars

            // SoundBars is a display-only region for now.
            visible: plasmoid.configuration.soundBarsInPanel
            playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }

        PanelIcon {
            id: panelIcon

            visible: plasmoid.configuration.iconInPanel
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            size: compact.iconSize
            icon: plasmoid.configuration.panelIcon
            imageUrl: player.artUrl
            imageRadius: plasmoid.configuration.albumCoverRadius
            fallbackToIconWhenImageNotAvailable: plasmoid.configuration.fallbackToIconWhenArtNotAvailable
            type: {
                if (!plasmoid.configuration.useAlbumCoverAsPanelIcon)
                    return PanelIcon.Type.Icon;

                return PanelIcon.Type.Image;
            }
        }

    }

    Controls.Popup {
        id: compactTextPopup

        width: 360
        height: Math.min(180, Math.max(70, compactTextEdit.implicitHeight + 28))
        padding: 12
        modal: false
        focus: false
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        onOpened: {
            const p = compact.mapToItem(compactTextPopup.parent, 0, compact.height);
            x = Math.max(0, p.x + (compact.width - width) / 2);
            y = p.y;
            compactTextEdit.forceActiveFocus();
        }

        background: Rectangle {
            radius: 8
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
        }

        contentItem: Controls.ScrollView {
            clip: true

            TextEdit {
                id: compactTextEdit

                width: compactTextPopup.availableWidth
                text: widget.displayText
                textFormat: TextEdit.AutoText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: Kirigami.Theme.textColor
                font: baseFont
                padding: 0
            }

        }

    }

    MouseArea {
        id: compactTextClickArea

        visible: songGrid.visible
        anchors.fill: songGrid
        z: 100
        acceptedButtons: Qt.LeftButton
        onClicked: {
            mouse.accepted = true;
            compactTextPopup.open();
        }
    }

    MouseArea {
        id: compactSoundBarsClickArea

        visible: soundBars.visible
        anchors.fill: soundBars
        z: 100
        acceptedButtons: Qt.LeftButton
        // Deliberately empty: SoundBars has no click interaction yet.
        onClicked: {
            mouse.accepted = true;
        }
    }

    MouseArea {
        id: compactIconClickArea

        visible: panelIcon.visible
        anchors.fill: panelIcon
        z: 100
        acceptedButtons: Qt.LeftButton
        onClicked: {
            mouse.accepted = true;
            widget.expanded = true;
        }
    }

    Behavior on backgroundColor {
        ColorAnimation {
            duration: Kirigami.Units.longDuration
        }

    }

    Behavior on foregroundColor {
        ColorAnimation {
            duration: Kirigami.Units.longDuration
        }

    }

    layer.effect: OpacityMask {

        maskSource: Item {
            width: compact.width
            height: compact.height

            Rectangle {
                anchors.fill: parent
                radius: compact.panelBackgroundRadius
            }

        }

    }

}
