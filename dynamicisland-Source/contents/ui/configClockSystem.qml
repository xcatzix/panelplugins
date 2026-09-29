import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Translator.js" as Tr

Kirigami.FormLayout {
    id: page

    property alias cfg_use24HourClock: clockSwitch.checked
    property alias cfg_showSeconds: secondsSwitch.checked
    property alias cfg_showDate: dateSwitch.checked
    property alias cfg_showCpuStat: cpuStatSwitch.checked
    property alias cfg_showRamStat: ramStatSwitch.checked
    property alias cfg_showTempStat: tempStatSwitch.checked
    property alias cfg_showFps: fpsSwitch.checked
    property string cfg_fpsStyle: "accent"

    QQC2.Switch {
        id: clockSwitch
        Kirigami.FormData.label: Tr.t("Clock:")
        text: Tr.t("Use 24-hour clock")
    }
    QQC2.Switch {
        id: secondsSwitch
        Kirigami.FormData.label: Tr.t("Seconds:")
        text: Tr.t("Show seconds")
    }
    QQC2.Switch {
        id: dateSwitch
        Kirigami.FormData.label: Tr.t("Date:")
        text: Tr.t("Show day and date")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.Label {
        Kirigami.FormData.label: Tr.t("System:")
        text: Tr.t("System usage is displayed together with the clock.")
        opacity: 0.7
    }
    QQC2.Switch {
        id: cpuStatSwitch
        Kirigami.FormData.label: Tr.t("Show:")
        text: Tr.t("CPU usage")
    }
    QQC2.Switch { id: ramStatSwitch; text: Tr.t("RAM usage") }
    QQC2.Switch { id: tempStatSwitch; text: Tr.t("CPU temperature") }

    Item { Kirigami.FormData.isSection: true }

    QQC2.Switch {
        id: fpsSwitch
        Kirigami.FormData.label: Tr.t("FPS counter:")
        text: Tr.t("Show frames-per-second next to System")
    }
    QQC2.ComboBox {
        id: fpsStyleCombo
        Kirigami.FormData.label: Tr.t("FPS style:")
        enabled: fpsSwitch.checked
        textRole: "text"
        valueRole: "value"
        model: [
            { text: Tr.t("Accent badge (e.g. 60 fps)"), value: "accent" },
            { text: Tr.t("Match system font (e.g. 60)"), value: "plain" }
        ]
        onActivated: page.cfg_fpsStyle = currentValue
        Component.onCompleted: currentIndex = indexOfValue(page.cfg_fpsStyle)
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: Tr.t("Clock and System are always shown from left to right. Clicking Clock opens KOrganizer; clicking System opens the task manager.")
    }
}
