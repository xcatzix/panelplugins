import "../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: compactConfigPage

    Layout.preferredWidth: form.implicitWidth

    property alias cfg_lyricInPanel: lyricInPanel.checked
    property alias cfg_separatorInPanel: separatorInPanel.checked
    property alias cfg_infoInPanel: infoInPanel.checked
    property alias cfg_soundBarsInPanel: soundBarsInPanel.checked
    property alias cfg_iconInPanel: iconInPanel.checked
    property alias cfg_controlsInPanel: controlsInPanel.checked
    property alias cfg_playerIconInPanel: playerIconInPanel.checked
    property alias cfg_lyricMaxWidth: lyricMaxWidth.value
    property alias cfg_lyricMargin: lyricMargin.value
    property alias cfg_infoWidth: infoWidth.value
    property alias cfg_infoMargin: infoMargin.value
    property alias cfg_soundBarsWidth: soundBarsWidth.value
    property alias cfg_soundBarsMargin: soundBarsMargin.value
    property alias cfg_soundBarsHeight: soundBarsHeight.value
    property alias cfg_iconWidth: iconWidth.value
    property alias cfg_iconMargin: iconMargin.value
    property alias cfg_controlsWidth: controlsWidth.value
    property alias cfg_controlsMargin: controlsMargin.value
    property alias cfg_playerIconWidth: playerIconWidth.value
    property alias cfg_playerIconMargin: playerIconMargin.value
    property alias cfg_infoShowArtist: infoShowArtist.checked
    property alias cfg_infoShowTitle: infoShowTitle.checked
    property alias cfg_infoShowAlbum: infoShowAlbum.checked
    property alias cfg_panelIcon: panelIcon.value
    property alias cfg_panelIconSizeRatio: panelIconSizeRatio.value
    property alias cfg_useAlbumCoverAsPanelIcon: useAlbumCoverAsPanelIcon.checked
    property alias cfg_fallbackToIconWhenArtNotAvailable: fallbackToIconWhenArtNotAvailable.checked
    property alias cfg_albumCoverRadius: albumCoverRadius.value
    property alias cfg_playerIconSource: playerIconSource.currentIndex
    property alias cfg_playerIconBuiltin: playerIconBuiltin.currentIndex
    property alias cfg_playerIconFile: iconFileDialog.value
    property alias cfg_playerIconTheme: playerIconTheme.value
    property alias cfg_playerIconSizeRatio: playerIconSizeRatio.value
    property alias cfg_playerIconRadius: playerIconRadius.value
    property alias cfg_playerProgramPath: playerProgramPath.text
    property alias cfg_controlSizeRatio: controlSizeRatio.value
    property alias cfg_lyricsWindowWidth: lyricsWindowWidth.value
    property alias cfg_lyricsWindowHeight: lyricsWindowHeight.value
    property alias cfg_lyricsWindowPadding: lyricsWindowPadding.value
    property alias cfg_lyricsWindowRadius: lyricsWindowRadius.value
    property alias cfg_lyricsWindowBorderWidth: lyricsWindowBorderWidth.value
    property alias cfg_lyricsWindowBorderColor: lyricsWindowBorderColor.color
    property alias cfg_compactTruncatedTextStyle: compactTruncatedTextStyle.currentIndex
    property alias cfg_textScrollingEnabled: textScrollingEnabled.checked
    property alias cfg_textScrollingSpeed: textScrollingSpeed.value
    property alias cfg_textScrollingBehaviour: textScrollingBehaviour.currentIndex
    property alias cfg_pauseTextScrollingWhileMediaIsNotPlaying: pauseTextScrollingWhileMediaIsNotPlaying.checked
    property alias cfg_textScrollingResetOnPause: textScrollingResetOnPause.checked
    property alias cfg_mediaProgressInPanel: mediaProgressInPanel.checked
    property alias cfg_colorsFromAlbumCover: colorsFromAlbumCover.checked
    property alias cfg_panelBackgroundRadius: panelBackgroundRadius.value

    Kirigami.FormLayout {
        id: form

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel boxes (left to right)")
        }

        CheckBox {
            id: lyricInPanel
            Kirigami.FormData.label: i18n("1. Lyric text")
        }

        CheckBox {
            id: separatorInPanel
            Kirigami.FormData.label: i18n("2. Separator |")
        }

        CheckBox {
            id: infoInPanel
            Kirigami.FormData.label: i18n("3. Artist / info (click opens Full)")
        }

        CheckBox {
            id: soundBarsInPanel
            Kirigami.FormData.label: i18n("4. Sound bars")
        }

        CheckBox {
            id: iconInPanel
            Kirigami.FormData.label: i18n("5. Icon (click opens Full)")
        }

        CheckBox {
            id: controlsInPanel
            Kirigami.FormData.label: i18n("6. Playback controls")
        }

        CheckBox {
            id: playerIconInPanel
            Kirigami.FormData.label: i18n("7. Player icon (click runs program)")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Box width (0 = automatic) and margin")
        }

        SpinBox {
            id: lyricMaxWidth
            Kirigami.FormData.label: i18n("Lyric width (px, max 150):")
            from: 0
            to: 150
            stepSize: 10
        }

        SpinBox {
            id: lyricMargin
            Kirigami.FormData.label: i18n("Lyric margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        SpinBox {
            id: infoWidth
            Kirigami.FormData.label: i18n("Info width (px):")
            from: 0
            to: 600
            stepSize: 10
        }

        SpinBox {
            id: infoMargin
            Kirigami.FormData.label: i18n("Info margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        SpinBox {
            id: soundBarsWidth
            Kirigami.FormData.label: i18n("Sound bars width (px):")
            from: 0
            to: 200
            stepSize: 10
        }

        SpinBox {
            id: soundBarsMargin
            Kirigami.FormData.label: i18n("Sound bars margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        SpinBox {
            id: soundBarsHeight
            Kirigami.FormData.label: i18n("Sound bars height (px, may exceed the box):")
            from: 4
            to: 200
            stepSize: 2
        }

        SpinBox {
            id: iconWidth
            Kirigami.FormData.label: i18n("Icon width (px):")
            from: 0
            to: 200
            stepSize: 10
        }

        SpinBox {
            id: iconMargin
            Kirigami.FormData.label: i18n("Icon margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        SpinBox {
            id: controlsWidth
            Kirigami.FormData.label: i18n("Controls width (px):")
            from: 0
            to: 300
            stepSize: 10
        }

        SpinBox {
            id: controlsMargin
            Kirigami.FormData.label: i18n("Controls margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        SpinBox {
            id: playerIconWidth
            Kirigami.FormData.label: i18n("Player icon width (px):")
            from: 0
            to: 200
            stepSize: 10
        }

        SpinBox {
            id: playerIconMargin
            Kirigami.FormData.label: i18n("Player icon margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Info contains:")
            enabled: infoInPanel.checked

            CheckBox { id: infoShowArtist; text: i18n("Artist") }
            CheckBox { id: infoShowTitle; text: i18n("Title") }
            CheckBox { id: infoShowAlbum; text: i18n("Album") }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Icon (5)")
        }

        ConfigIcon {
            id: panelIcon
            Kirigami.FormData.label: i18n("Theme icon:")
        }

        Slider {
            id: panelIconSizeRatio
            Kirigami.FormData.label: i18n("Size:")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0.6
            to: 1
            stepSize: 0.05
        }

        CheckBox {
            id: useAlbumCoverAsPanelIcon
            Kirigami.FormData.label: i18n("Use album cover as icon")
        }

        CheckBox {
            id: fallbackToIconWhenArtNotAvailable
            Kirigami.FormData.label: i18n("Fallback to theme icon if cover is not available")
        }

        Slider {
            id: albumCoverRadius
            Kirigami.FormData.label: i18n("Corners (0 square - 100 round):")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            enabled: useAlbumCoverAsPanelIcon.checked
            from: 0
            to: 100
            stepSize: 5
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Player icon (7)")
        }

        ComboBox {
            id: playerIconSource
            Kirigami.FormData.label: i18n("Icon source:")
            model: [i18n("Built-in (assets)"), i18n("Own image file"), i18n("Theme icon")]
        }

        ComboBox {
            id: playerIconBuiltin
            Kirigami.FormData.label: i18n("Built-in icon:")
            visible: playerIconSource.currentIndex === 0
            model: ["Netease Cloud Music", "Spotify"]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Image file:")
            visible: playerIconSource.currentIndex === 1

            Button {
                text: i18n("Choose…")
                icon.name: "document-open"
                onClicked: iconFileDialog.open()
            }

            Button {
                text: i18n("Clear")
                icon.name: "edit-delete"
                visible: iconFileDialog.value
                onClicked: iconFileDialog.value = ""
            }
        }

        Label {
            visible: playerIconSource.currentIndex === 1 && iconFileDialog.value
            text: iconFileDialog.value
            elide: Text.ElideMiddle
            Layout.maximumWidth: 25 * Kirigami.Units.gridUnit
        }

        ConfigIcon {
            id: playerIconTheme
            Kirigami.FormData.label: i18n("Theme icon:")
            visible: playerIconSource.currentIndex === 2
        }

        Slider {
            id: playerIconSizeRatio
            Kirigami.FormData.label: i18n("Size:")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0.6
            to: 1
            stepSize: 0.05
        }

        Slider {
            id: playerIconRadius
            Kirigami.FormData.label: i18n("Corners (0 square - 100 round):")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0
            to: 100
            stepSize: 5
        }

        TextField {
            id: playerProgramPath
            Kirigami.FormData.label: i18n("Program to run on click:")
            Layout.preferredWidth: 18 * Kirigami.Units.gridUnit
            placeholderText: i18n("e.g. netease-cloud-music (empty = raise player)")
        }

        Slider {
            id: controlSizeRatio
            Kirigami.FormData.label: i18n("Playback controls size:")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0.3
            to: 0.9
            stepSize: 0.05
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Lyrics window")
        }

        SpinBox {
            id: lyricsWindowWidth
            Kirigami.FormData.label: i18n("Width (px):")
            from: 150
            to: 600
            stepSize: 10
        }

        SpinBox {
            id: lyricsWindowHeight
            Kirigami.FormData.label: i18n("Height (px):")
            from: 100
            to: 800
            stepSize: 10
        }

        SpinBox {
            id: lyricsWindowPadding
            Kirigami.FormData.label: i18n("Margin (px):")
            from: 0
            to: 40
            stepSize: 1
        }

        Slider {
            id: lyricsWindowRadius
            Kirigami.FormData.label: i18n("Corners (0 square - 100 round):")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0
            to: 100
            stepSize: 5
        }

        SpinBox {
            id: lyricsWindowBorderWidth
            Kirigami.FormData.label: i18n("Border width (px, 0 = none):")
            from: 0
            to: 10
        }

        KQuickControls.ColorButton {
            id: lyricsWindowBorderColor
            Kirigami.FormData.label: i18n("Border color:")
            showAlphaChannel: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Text")
        }

        ComboBox {
            id: compactTruncatedTextStyle
            Kirigami.FormData.label: i18n("Truncated text style:")
            model: [i18n("Elide"), i18n("Fade out"), i18n("None")]
        }

        CheckBox {
            id: textScrollingEnabled
            Kirigami.FormData.label: i18n("Scroll text that is too long")
        }

        Slider {
            id: textScrollingSpeed
            Kirigami.FormData.label: i18n("Speed:")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            enabled: textScrollingEnabled.checked
            from: 1
            to: 10
            stepSize: 1
        }

        ComboBox {
            id: textScrollingBehaviour
            Kirigami.FormData.label: i18n("When text overflows:")
            enabled: textScrollingEnabled.checked
            model: [i18n("Always scroll"), i18n("Scroll only on mouse over"), i18n("Always scroll except on mouse over")]
        }

        CheckBox {
            id: pauseTextScrollingWhileMediaIsNotPlaying
            Kirigami.FormData.label: i18n("Pause scrolling while media is not playing")
        }

        CheckBox {
            id: textScrollingResetOnPause
            Kirigami.FormData.label: i18n("Reset position when scrolling is paused")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel background")
        }

        CheckBox {
            id: mediaProgressInPanel
            Kirigami.FormData.label: i18n("Media progress")
        }

        CheckBox {
            id: colorsFromAlbumCover
            Kirigami.FormData.label: i18n("Colors from album cover (needs Use album cover as icon)")
        }

        Slider {
            id: panelBackgroundRadius
            Kirigami.FormData.label: i18n("Corners (0 square - 100 round):")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 0
            to: 100
            stepSize: 5
        }
    }

    QtDialogs.FileDialog {
        id: iconFileDialog

        property string value: ""

        title: i18n("Choose an icon image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.svg *.webp *.gif *.bmp)")]
        onAccepted: value = selectedFile.toString()
    }
}
