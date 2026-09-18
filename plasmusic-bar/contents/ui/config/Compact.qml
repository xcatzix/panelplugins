import "../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM


KCM.SimpleKCM {
    id: compactConfigPage
    Layout.preferredWidth: form.implicitWidth;

    property alias cfg_panelIcon: panelIcon.value
    property alias cfg_useAlbumCoverAsPanelIcon: useAlbumCoverAsPanelIcon.checked
    property alias cfg_fallbackToIconWhenArtNotAvailable: fallbackToIconWhenArtNotAvailable.checked
    property alias cfg_albumCoverRadius: albumCoverRadius.value
    property alias cfg_songTextInPanel: songTextInPanel.checked
    property alias cfg_soundBarsInPanel: soundBarsInPanel.checked
    property alias cfg_iconInPanel: iconInPanel.checked
    property alias cfg_songTextFixedWidth: songTextFixedWidth.value
    property alias cfg_textScrollingSpeed: textScrollingSpeed.value
        property alias cfg_textScrollingEnabled: textScrollingEnabledCheckbox.checked
    property alias cfg_textScrollingBehaviour: scrollingBehaviourValue.value
    property alias cfg_textScrollingResetOnPause: textScrollingResetOnPauseCheckbox.checked
    property alias cfg_colorsFromAlbumCover: colorsFromAlbumCover.checked
    property alias cfg_panelBackgroundRadius: panelBackgroundRadius.value
    property alias cfg_panelIconSizeRatio: panelIconSizeRatio.value

    Kirigami.FormLayout {
        id: form

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Layout")
        }

        CheckBox {
            id: iconInPanel
            Kirigami.FormData.label: i18n("Show icon:")
        }

        CheckBox {
            id: songTextInPanel
            Kirigami.FormData.label: i18n("Show text")
        }

        CheckBox {
            id: soundBarsInPanel
            Kirigami.FormData.label: i18n("Show soundbars")
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Icon customization")
        }

        ConfigIcon {
            id: panelIcon
            Kirigami.FormData.label: i18n("Icon:")
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            id: panelIconSizeRatio
            from: 0.6
            to: 1
            stepSize: 0.05
            Kirigami.FormData.label: i18n("Size:")
        }

        CheckBox {
            id: useAlbumCoverAsPanelIcon
            Kirigami.FormData.label: i18n("Use album cover as icon")
        }

        CheckBox {
            id: fallbackToIconWhenArtNotAvailable
            enabled: useAlbumCoverAsPanelIcon.checked
            Kirigami.FormData.label: i18n("Fallback to icon if cover is not available")
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            enabled: useAlbumCoverAsPanelIcon.checked
            id: albumCoverRadius
            from: 0
            to: 25
            stepSize: 2
            Kirigami.FormData.label: i18n("Album cover radius:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Text")
        }

        SpinBox {
            id: songTextFixedWidth
            from: 40
            to: 1000
            value: 200
            Kirigami.FormData.label: i18n("Fixed width:")
            enabled: songTextInPanel.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Text scrolling")
        }

        QtObject {
            id: scrollingBehaviourValue
            property int value: 0
        }

        CheckBox {
            id: textScrollingEnabledCheckbox
            Kirigami.FormData.label: i18n("Enabled")
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            id: textScrollingSpeed
            from: 1
            to: 10
            stepSize: 1
            Kirigami.FormData.label: i18n("Speed:")
            enabled: textScrollingEnabledCheckbox.checked
        }

        RadioButton {
            Kirigami.FormData.label: i18n("When text overflows:")
            id: alwaysScroll
            text: i18n("Always scroll")
            checked: scrollingBehaviourValue.value === 0
            onClicked: scrollingBehaviourValue.value = 0
            enabled: textScrollingEnabledCheckbox.checked
        }

        RadioButton {
            id: scrollOnMouseOver
            text: i18n("Scroll only on mouse over")
            checked: scrollingBehaviourValue.value === 1
            onClicked: scrollingBehaviourValue.value = 1
            enabled: textScrollingEnabledCheckbox.checked
        }

        RadioButton {
            id: stopOnMouseOver
            text: i18n("Always scroll except on mouse over")
            checked: scrollingBehaviourValue.value === 2
            onClicked: scrollingBehaviourValue.value = 2
            enabled: textScrollingEnabledCheckbox.checked
        }


        CheckBox {
            id: textScrollingResetOnPauseCheckbox
            Kirigami.FormData.label: i18n("Reset position when scrolling is paused")
            enabled: textScrollingEnabledCheckbox.checked
        }

    }
}
