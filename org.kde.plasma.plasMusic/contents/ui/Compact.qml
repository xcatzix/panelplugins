import "./components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

// Panel layout, left -> right:
//   lyric | separator | artist/info | sound bars | icon | controls | player icon
//
//   lyric text  -> floating window with the full lyrics (scrollable)
//   artist info -> opens the Full view
//   sound bars  -> display only
//   icon        -> (original plasmusic icon: theme icon / album cover) opens the Full view
//   controls    -> previous / play-pause / next  (images from assets)
//   player icon -> runs the configured program (or raises the player)
//
// Every box has a fixed-width setting (0 = automatic) and a margin setting,
// except the lyric box which is 0..150 px and follows its text.
Item {
    id: compact

    readonly property var cfg: plasmoid.configuration
    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property int widgetThickness: horizontal ? height : width
    readonly property int iconSize: Math.round(widgetThickness * cfg.panelIconSizeRatio)
    readonly property int playerIconSize: Math.round(widgetThickness * cfg.playerIconSizeRatio)
    readonly property int controlSize: Math.max(10, Math.round(widgetThickness * cfg.controlSizeRatio))
    readonly property int lengthMargin: Math.max(Kirigami.Units.smallSpacing, Math.round((widgetThickness - Math.max(controlSize, iconSize, playerIconSize)) / 2))
    readonly property bool hasMedia: player.hasActiveMedia
    readonly property bool colorsFromAlbumCover: cfg.colorsFromAlbumCover
    readonly property int panelBackgroundRadius: Math.round(cfg.panelBackgroundRadius / 100 * Math.min(width, height) / 2)
    readonly property bool useImageColors: panelIcon.imageReady && panelIcon.type == PanelIcon.Type.Image && colorsFromAlbumCover
    readonly property color imageColor: useImageColors ? panelIcon.imageColor : Kirigami.Theme.textColor
    readonly property color backgroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, "black", 0.5)
    property color backgroundColor: useImageColors ? backgroundColorFromImage : "transparent"
    readonly property var backgroundColorBrightness: Kirigami.ColorUtils.brightnessForColor(backgroundColor)
    readonly property color contrastColor: backgroundColorBrightness === Kirigami.ColorUtils.Dark ? "white" : "#1a1a1a"
    readonly property color foregroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, contrastColor, 0.6)
    property color foregroundColor: useImageColors ? foregroundColorFromImage : Kirigami.Theme.textColor
    // assets come in a dark and a "-white" variant: pick by the foreground brightness
    readonly property bool lightForeground: Kirigami.ColorUtils.brightnessForColor(foregroundColor) === Kirigami.ColorUtils.Light
    readonly property var builtinPlayerIcons: ["netease-cloud-music", "spotify"]

    // Lyric box: only while media is playing (current lyric line, else the song title).
    readonly property string lyricDisplay: {
        if (!hasMedia)
            return "";
        if (cfg.lyricsEnabled && lyrics.currentLine)
            return lyrics.currentLine;
        return player.title;
    }
    // Info box (the song text): shows the "no media" / custom text when nothing plays
    // (or while playing, if "Show this text while media is playing" is ticked),
    // otherwise artist / title / album.
    readonly property string infoDisplay: {
        if (!hasMedia || cfg.showCustomTextWithMedia)
            return flat(widget.displayText);
        const parts = [];
        if (cfg.infoShowArtist && player.artists)
            parts.push(player.artists);
        if (cfg.infoShowTitle && player.title)
            parts.push(player.title);
        if (cfg.infoShowAlbum && player.album)
            parts.push(player.album);
        return parts.join(" - ");
    }
    property double lyricsClosedAt: 0

    function flat(s) {
        return String(s || "").replace(/\s*[\r\n]+\s*/g, "  ");
    }

    function asset(name) {
        return Qt.resolvedUrl("assets/" + name + (lightForeground ? "-white" : "") + ".svg");
    }

    function launchPlayer() {
        const path = String(cfg.playerProgramPath || "").trim();
        if (path.length > 0)
            launcher.run("setsid sh -c " + launcher.quote(path) + " >/dev/null 2>&1 &");
        else if (player.canRaise)
            player.raise();
        else
            widget.expanded = true;
    }

    Layout.preferredWidth: horizontal ? grid.implicitWidth + lengthMargin * 2 : grid.implicitWidth
    Layout.preferredHeight: !horizontal ? grid.implicitHeight + lengthMargin * 2 : grid.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.fillHeight: horizontal
    Layout.fillWidth: !horizontal

    Shell {
        id: launcher
    }

    Rectangle {
        id: backgroundRect

        anchors.fill: parent
        color: backgroundColor
        layer.enabled: compact.panelBackgroundRadius > 0 && (!Qt.colorEqual(backgroundColor, "transparent") || cfg.mediaProgressInPanel)

        layer.effect: OpacityMask {

            maskSource: Item {
                width: backgroundRect.width
                height: backgroundRect.height

                Rectangle {
                    anchors.fill: parent
                    radius: compact.panelBackgroundRadius
                }

            }

        }

        Rectangle {
            id: progress

            color: "#82c7ff"
            height: horizontal ? parent.height : (player.songLength > 0 ? parent.height * (player.songPosition / player.songLength) : 0)
            width: horizontal ? (player.songLength > 0 ? parent.width * (player.songPosition / player.songLength) : 0) : parent.width
            visible: cfg.mediaProgressInPanel
            opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 0.88 : 0.45
        }

    }

    // Generic panel clicks (gaps between the boxes below)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                player.playPause();
            } else if (mouse.modifiers & Qt.ControlModifier) {
                if (player.canRaise)
                    player.raise();

            } else {
                widget.expanded = !widget.expanded;
            }
        }
    }

    GridLayout {
        id: grid

        columns: horizontal ? grid.children.length : 1
        rows: horizontal ? 1 : grid.children.length
        columnSpacing: Kirigami.Units.smallSpacing * 2
        rowSpacing: Kirigami.Units.smallSpacing * 2
        anchors.leftMargin: horizontal ? lengthMargin : 0
        anchors.rightMargin: horizontal ? lengthMargin : 0
        anchors.bottomMargin: horizontal ? 0 : lengthMargin
        anchors.topMargin: horizontal ? 0 : lengthMargin
        anchors.fill: parent

        // 1. lyric text: 0..150 px, grows with the text, scrolls when longer
        PanelSlot {
            id: lyricSlot

            horizontal: compact.horizontal
            slotMargin: cfg.lyricMargin
            autoSize: lyricText.width
            visible: compact.horizontal && cfg.lyricInPanel && cfg.lyricMaxWidth > 0 && lyricText.text.length > 0

            ScrollingText {
                id: lyricText

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                maxWidth: Math.max(0, Math.min(150, cfg.lyricMaxWidth))
                text: compact.lyricDisplay
                font: widget.baseFont
                color: foregroundColor
                speed: cfg.textScrollingSpeed
                overflowBehaviour: cfg.textScrollingBehaviour
                scrollingEnabled: cfg.textScrollingEnabled
                scrollResetOnPause: cfg.textScrollingResetOnPause
                truncateStyle: cfg.compactTruncatedTextStyle
                forcePauseScrolling: cfg.pauseTextScrollingWhileMediaIsNotPlaying && player.playbackStatus !== Mpris.PlaybackStatus.Playing
                opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 1 : 0.75
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (lyricsDialog.visible)
                        lyricsDialog.visible = false;
                    else if (Date.now() - compact.lyricsClosedAt > 300)
                        lyricsDialog.visible = true;
                }
            }

        }

        // 2. separator "|" between lyric and info
        PanelSlot {
            id: separatorSlot

            horizontal: compact.horizontal
            autoSize: separatorText.implicitWidth
            visible: lyricSlot.visible && infoSlot.visible && cfg.separatorInPanel
            opacity: infoText.text.length > 0 ? 0.7 : 0

            Text {
                id: separatorText

                anchors.centerIn: parent
                text: "|"
                font: widget.baseFont
                color: foregroundColor
            }

        }

        // 3. artist / other info: fixed width, click opens Full
        PanelSlot {
            id: infoSlot

            horizontal: compact.horizontal
            fixedWidth: cfg.infoWidth
            slotMargin: cfg.infoMargin
            visible: compact.horizontal && cfg.infoInPanel && cfg.infoWidth > 0

            ScrollingText {
                id: infoText

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                maxWidth: cfg.infoWidth
                text: compact.infoDisplay
                font: widget.baseFont
                color: foregroundColor
                speed: cfg.textScrollingSpeed
                overflowBehaviour: cfg.textScrollingBehaviour
                scrollingEnabled: cfg.textScrollingEnabled
                scrollResetOnPause: cfg.textScrollingResetOnPause
                truncateStyle: cfg.compactTruncatedTextStyle
                forcePauseScrolling: cfg.pauseTextScrollingWhileMediaIsNotPlaying && player.playbackStatus !== Mpris.PlaybackStatus.Playing
                opacity: !hasMedia || player.playbackStatus === Mpris.PlaybackStatus.Playing ? 0.9 : 0.6
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: widget.expanded = true
            }

        }

        // 4. sound bars (display only)
        PanelSlot {
            id: soundBarsSlot

            horizontal: compact.horizontal
            fixedWidth: cfg.soundBarsWidth
            slotMargin: cfg.soundBarsMargin
            autoSize: soundBars.implicitWidth
            visible: cfg.soundBarsInPanel

            SoundBars {
                id: soundBars

                anchors.centerIn: parent
                // may be taller than the panel box: nothing here clips it
                barHeight: cfg.soundBarsHeight
                playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            }

        }

        // 5. icon: the original plasmusic icon (theme icon or album cover), click opens Full
        PanelSlot {
            id: iconSlot

            horizontal: compact.horizontal
            fixedWidth: cfg.iconWidth
            slotMargin: cfg.iconMargin
            autoSize: compact.iconSize
            visible: cfg.iconInPanel && (panelIcon.type === PanelIcon.Type.Icon || panelIcon.imageReady || panelIcon.fallbackToIconWhenImageNotAvailable)

            PanelIcon {
                id: panelIcon

                anchors.centerIn: parent
                size: compact.iconSize
                icon: cfg.panelIcon
                imageUrl: player.artUrl
                imageRadius: Math.round(cfg.albumCoverRadius / 100 * compact.iconSize / 2)
                fallbackToIconWhenImageNotAvailable: cfg.fallbackToIconWhenArtNotAvailable
                type: cfg.useAlbumCoverAsPanelIcon ? PanelIcon.Type.Image : PanelIcon.Type.Icon
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: widget.expanded = true
            }

        }

        // 6. playback controls (assets)
        PanelSlot {
            id: controlsSlot

            horizontal: compact.horizontal
            fixedWidth: cfg.controlsWidth
            slotMargin: cfg.controlsMargin
            autoSize: controlsRow.implicitWidth
            visible: cfg.controlsInPanel && player.ready

            RowLayout {
                id: controlsRow

                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 2

                CommandIcon {
                    size: compact.controlSize
                    source: compact.asset("media-backward")
                    onClicked: player.previous()
                }

                CommandIcon {
                    size: compact.controlSize
                    source: compact.asset(player.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-pause" : "media-play")
                    onClicked: player.playPause()
                }

                CommandIcon {
                    size: compact.controlSize
                    source: compact.asset("media-forward")
                    onClicked: player.next()
                }

            }

        }

        // 7. player icon (default: asset icon), click runs the configured program
        PanelSlot {
            id: playerIconSlot

            horizontal: compact.horizontal
            fixedWidth: cfg.playerIconWidth
            slotMargin: cfg.playerIconMargin
            autoSize: compact.playerIconSize
            visible: cfg.playerIconInPanel

            PanelIcon {
                id: playerIcon

                anchors.centerIn: parent
                size: compact.playerIconSize
                icon: cfg.playerIconTheme
                imageUrl: cfg.playerIconSource === 0 ? compact.asset(compact.builtinPlayerIcons[Math.max(0, Math.min(cfg.playerIconBuiltin, compact.builtinPlayerIcons.length - 1))]) : cfg.playerIconFile
                imageRadius: Math.round(cfg.playerIconRadius / 100 * compact.playerIconSize / 2)
                fallbackToIconWhenImageNotAvailable: true
                type: cfg.playerIconSource === 2 ? PanelIcon.Type.Icon : PanelIcon.Type.Image
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: compact.launchPlayer()
            }

        }

    }

    PlasmaCore.Dialog {
        id: lyricsDialog

        visualParent: compact
        location: widget.location
        hideOnWindowDeactivate: true
        onVisibleChanged: {
            if (!visible)
                compact.lyricsClosedAt = Date.now();

        }

        mainItem: LyricsView {
            provider: lyrics
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

}
