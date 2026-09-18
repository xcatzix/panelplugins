import "./components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

Item {
    id: compact

    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property int widgetThickness: horizontal ? height : width
    readonly property int iconSize: Math.max(1, Math.round(widgetThickness * plasmoid.configuration.panelIconSizeRatio))
    readonly property int panelBackgroundRadius: plasmoid.configuration.panelBackgroundRadius
    readonly property bool useImageColors: panelIcon.imageReady && panelIcon.type === PanelIcon.Type.Image && plasmoid.configuration.colorsFromAlbumCover
    readonly property color imageColor: useImageColors ? panelIcon.imageColor : Kirigami.Theme.textColor
    readonly property color backgroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, "black", 0.5)
    property color backgroundColor: useImageColors ? backgroundColorFromImage : "transparent"
    readonly property var backgroundColorBrightness: Kirigami.ColorUtils.brightnessForColor(backgroundColor)
    readonly property color contrastColor: backgroundColorBrightness === Kirigami.ColorUtils.Dark ? "white" : "black"
    readonly property color foregroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, contrastColor, 0.6)
    property color foregroundColor: useImageColors ? foregroundColorFromImage : Kirigami.Theme.textColor

    readonly property bool showText: plasmoid.configuration.songTextInPanel
    readonly property bool showSoundBars: plasmoid.configuration.soundBarsInPanel
    readonly property bool showIcon: plasmoid.configuration.iconInPanel
    readonly property bool mediaHasText: player.ready && (player.title.length > 0 || player.artists.length > 0 || player.album.length > 0)
    readonly property bool showDisplayText: showText && (!mediaHasText || plasmoid.configuration.showCustomTextWithMedia)

    Layout.preferredWidth: horizontal ? content.implicitWidth : content.implicitWidth
    Layout.preferredHeight: horizontal ? content.implicitHeight : content.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.fillHeight: !horizontal
    Layout.fillWidth: horizontal
    layer.enabled: panelBackgroundRadius > 0

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
    }

    // Compact is display-only: no mouse media controls.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: widget.expanded = !widget.expanded
    }

    RowLayout {
        id: content
        visible: horizontal
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        ScrollingText {
            visible: compact.showDisplayText
            Layout.preferredWidth: plasmoid.configuration.songTextFixedWidth
            Layout.minimumWidth: plasmoid.configuration.songTextFixedWidth
            Layout.maximumWidth: plasmoid.configuration.songTextFixedWidth
            Layout.alignment: Qt.AlignVCenter
            text: widget.displayText
            font: baseFont
            color: foregroundColor
            scrollingEnabled: plasmoid.configuration.textScrollingEnabled
            scrollingBehaviour: plasmoid.configuration.textScrollingBehaviour
            speed: plasmoid.configuration.textScrollingSpeed
            scrollResetOnPause: plasmoid.configuration.textScrollingResetOnPause
        }

        SoundBars {
            visible: compact.showSoundBars
            Layout.preferredWidth: barCount * (barWidth + barSpacing) - barSpacing
            Layout.preferredHeight: Math.max(1, compact.widgetThickness * 0.55)
            playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            barCount: 6
            barWidth: 2
            barHeight: Math.max(8, compact.widgetThickness * 0.55)
            barSpacing: 1.5
        }

        PanelIcon {
            id: panelIcon
            visible: compact.showIcon
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
            size: compact.iconSize
            icon: plasmoid.configuration.panelIcon
            imageUrl: player.artUrl
            imageRadius: plasmoid.configuration.albumCoverRadius
            fallbackToIconWhenImageNotAvailable: plasmoid.configuration.fallbackToIconWhenArtNotAvailable
            type: plasmoid.configuration.useAlbumCoverAsPanelIcon ? PanelIcon.Type.Image : PanelIcon.Type.Icon
        }
    }

    ColumnLayout {
        id: verticalContent
        visible: !horizontal
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        ScrollingText {
            visible: compact.showDisplayText
            Layout.preferredWidth: plasmoid.configuration.songTextFixedWidth
            Layout.minimumWidth: plasmoid.configuration.songTextFixedWidth
            Layout.maximumWidth: plasmoid.configuration.songTextFixedWidth
            Layout.preferredHeight: implicitHeight
            text: widget.displayText
            font: baseFont
            color: foregroundColor
            rotation: widget.location === PlasmaCore.Types.LeftEdge ? -90 : 90
            scrollingEnabled: plasmoid.configuration.textScrollingEnabled
            scrollingBehaviour: plasmoid.configuration.textScrollingBehaviour
            speed: plasmoid.configuration.textScrollingSpeed
            scrollResetOnPause: plasmoid.configuration.textScrollingResetOnPause
        }

        SoundBars {
            visible: compact.showSoundBars
            Layout.preferredWidth: barCount * (barWidth + barSpacing) - barSpacing
            Layout.preferredHeight: Math.max(8, compact.widgetThickness * 0.55)
            playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            barCount: 6
            barWidth: 2
            barHeight: Math.max(8, compact.widgetThickness * 0.55)
            barSpacing: 1.5
        }

        PanelIcon {
            visible: compact.showIcon
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
            size: compact.iconSize
            icon: plasmoid.configuration.panelIcon
            imageUrl: player.artUrl
            imageRadius: plasmoid.configuration.albumCoverRadius
            fallbackToIconWhenImageNotAvailable: plasmoid.configuration.fallbackToIconWhenArtNotAvailable
            type: plasmoid.configuration.useAlbumCoverAsPanelIcon ? PanelIcon.Type.Image : PanelIcon.Type.Icon
        }
    }

    Behavior on backgroundColor {
        ColorAnimation { duration: Kirigami.Units.longDuration }
    }

    Behavior on foregroundColor {
        ColorAnimation { duration: Kirigami.Units.longDuration }
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
