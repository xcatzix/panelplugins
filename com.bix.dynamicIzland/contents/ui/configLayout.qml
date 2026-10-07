import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Translator.js" as Tr

Kirigami.FormLayout {
    id: page
    property alias cfg_moduleSeparators: separatorsSwitch.checked
    property alias cfg_popupGap: gapSpin.value

    QQC2.Switch {
        id: separatorsSwitch
        Kirigami.FormData.label: Tr.t("Separators:")
        text: Tr.t("Show “/” dividers between modules")
    }

    QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        wrapMode: Text.WordWrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: Tr.t("The compact layout is fixed from left to right as Clock, System (with FPS), Notification.")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.SpinBox {
        id: gapSpin
        Kirigami.FormData.label: Tr.t("Distance from panel:")
        from: 0; to: 120; stepSize: 2
    }

    QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        wrapMode: Text.WordWrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: Tr.t("Gap between the small capsule and the big expanded panel. Increase it if the panel appears too close to or overlapping the capsule.")
    }
}
