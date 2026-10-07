import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "Translator.js" as Tr

Kirigami.FormLayout {
    property alias cfg_enableDownloads: downloadsSwitch.checked
    property alias cfg_enableScreenSharing: sharingSwitch.checked
    property alias cfg_ideBuildEnabled: ideSwitch.checked
    property alias cfg_showNetSpeed: netSwitch.checked

    QQC2.Switch { id: downloadsSwitch; Kirigami.FormData.label: Tr.t("Downloads:"); text: Tr.t("Show active jobs / progress") }
    QQC2.Switch { id: sharingSwitch; Kirigami.FormData.label: Tr.t("Screen sharing:"); text: Tr.t("Show capture / presentation state") }
    QQC2.Switch { id: ideSwitch; Kirigami.FormData.label: Tr.t("IntelliJ IDEA:"); text: Tr.t("Show build results (e.g. JAR build succeeded)") }
    QQC2.Switch { id: netSwitch; Kirigami.FormData.label: Tr.t("Network speed:"); text: Tr.t("Show speed when there are no notifications") }
}
