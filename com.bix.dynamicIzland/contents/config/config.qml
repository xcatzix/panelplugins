import QtQuick
import org.kde.plasma.configuration
import "../ui/Translator.js" as Tr

ConfigModel {
    ConfigCategory {
        name: Tr.t("Size & Shape")
        icon: "transform-scale"
        source: "configSize.qml"
    }
    ConfigCategory {
        name: Tr.t("Layout")
        icon: "view-split-left-right"
        source: "configLayout.qml"
    }
    ConfigCategory {
        name: Tr.t("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: Tr.t("Clock & System")
        icon: "preferences-system-time"
        source: "configClockSystem.qml"
    }
    ConfigCategory {
        name: Tr.t("Notifications")
        icon: "preferences-desktop-notification-bell"
        source: "configNotifications.qml"
    }
    ConfigCategory {
        name: Tr.t("Modules")
        icon: "view-visible"
        source: "configFeatures.qml"
    }
    ConfigCategory {
        name: Tr.t("Animation")
        icon: "preferences-desktop-effects"
        source: "configAnimation.qml"
    }
}
