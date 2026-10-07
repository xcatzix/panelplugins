import QtQuick
import QtQuick.Layouts
import "Translator.js" as Tr
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // The capsule has a fixed, user-adjustable width (Size & Shape settings); the
    // notification/network area inside it elides instead of stretching the island.
    readonly property int compactWidth: Plasmoid.configuration.compactWidth
    readonly property int compactSidePadding: 18
    readonly property int expandedWidth: logView ? Math.max(420, Plasmoid.configuration.expandedWidthNotification) : activeMode === 2 ? Plasmoid.configuration.expandedWidthNotification : Plasmoid.configuration.expandedWidthStatus
    readonly property int compactHeight: 32
    readonly property int expandedHeight: logView ? 320 : Plasmoid.configuration.expandedHeight
    readonly property bool animationsEnabled: Plasmoid.configuration.animationsEnabled
    readonly property real animMultiplier: 100 / Math.max(40, Plasmoid.configuration.animationSpeed)
    readonly property string accent: Plasmoid.configuration.accentColor
    readonly property int cornerRadius: Plasmoid.configuration.cornerRadius
    readonly property bool backgroundEnabled: Plasmoid.configuration.backgroundEnabled
    readonly property bool borderEnabled: Plasmoid.configuration.borderEnabled
    readonly property bool followTheme: Plasmoid.configuration.followSystemTheme
    readonly property color panelBackground: !backgroundEnabled ? "transparent" : withAlpha(followTheme ? Kirigami.Theme.backgroundColor : Plasmoid.configuration.backgroundColor, Plasmoid.configuration.backgroundOpacity)
    readonly property color borderColor: (borderEnabled && backgroundEnabled) ? (followTheme ? withAlpha(Kirigami.Theme.textColor, 16) : Qt.rgba(1, 1, 1, 0.16)) : Qt.rgba(0, 0, 0, 0)
    // Primary/secondary text colors. On a transparent panel white reads best, but
    // when the user opts into the Plasma theme we follow its text color instead.
    readonly property color textPrimary: followTheme ? Kirigami.Theme.textColor : "white"
    readonly property color textSecondary: followTheme ? withAlpha(Kirigami.Theme.textColor, 75) : Qt.rgba(1, 1, 1, 0.74)
    readonly property string idleDotColor: Plasmoid.configuration.idleDotColor
    readonly property string sharingDotColor: Plasmoid.configuration.sharingDotColor
    readonly property string timeText: {
        let fmt = Plasmoid.configuration.use24HourClock ? "HH:mm" : "h:mm";
        if (Plasmoid.configuration.showSeconds)
            fmt += ":ss";

        if (!Plasmoid.configuration.use24HourClock)
            fmt += " AP";

        let out = Qt.formatTime(currentTime, fmt);
        if (Plasmoid.configuration.showDate)
            out = Qt.formatDate(currentTime, "ddd d") + "  " + out;

        return out;
    }
    readonly property bool enableNotifications: Plasmoid.configuration.enableNotifications
    readonly property bool enableDownloads: Plasmoid.configuration.enableDownloads
    readonly property bool enableScreenSharing: Plasmoid.configuration.enableScreenSharing
    readonly property bool showFps: Plasmoid.configuration.showFps
    readonly property bool showNetSpeed: Plasmoid.configuration.showNetSpeed
    readonly property string netSpeedText: netLoader.item ? netLoader.item.text : ""
    readonly property string netSpeedStyled: netLoader.item ? "<font color='#08150a'>↓ " + netLoader.item.formatSpeed(netLoader.item.rxSpeed) + "</font>  <font color='" + accent + "'>↑ " + netLoader.item.formatSpeed(netLoader.item.txSpeed) + "</font>" : ""
    readonly property string fpsStyle: Plasmoid.configuration.fpsStyle
    readonly property bool moduleSeparators: Plasmoid.configuration.moduleSeparators
    readonly property real cpuUsage: sysLoader.item ? sysLoader.item.cpuUsage : 0
    readonly property real ramUsage: sysLoader.item ? sysLoader.item.ramUsage : 0
    readonly property real cpuTemp: sysLoader.item ? sysLoader.item.cpuTemp : 0
    readonly property bool showCpuStat: Plasmoid.configuration.showCpuStat
    readonly property bool showRamStat: Plasmoid.configuration.showRamStat
    readonly property bool showTempStat: Plasmoid.configuration.showTempStat
    readonly property string statsText: {
        let parts = [];
        if (showCpuStat)
            parts.push("CPU " + Math.round(cpuUsage) + "%");

        if (showRamStat)
            parts.push("RAM " + Math.round(ramUsage) + "%");

        if (showTempStat && cpuTemp > 0)
            parts.push(Math.round(cpuTemp) + "°C");

        return parts.join("  ");
    }
    readonly property int fps: fpsMeter.smoothFrameTime > 0 ? Math.round(1 / fpsMeter.smoothFrameTime) : 0
    readonly property bool sharingScreen: enableScreenSharing && notificationSettings.notificationsInhibitedByApplication
    readonly property bool hasNotification: enableNotifications && notificationPulse.running
    readonly property bool hasJobs: enableDownloads && jobsCount > 0
    readonly property bool idleMode: !sharingScreen && !eventTimer.running && !hasNotification && !buildTimer.running && !hasJobs
    readonly property bool showGreenDot: idleMode
    readonly property int activeMode: {
        if (buildTimer.running)
            return 8;

        if (hasNotification)
            return 2;

        if (eventTimer.running && modeIndex !== 0)
            return modeIndex;

        if (hasJobs)
            return 5;

        if (sharingScreen)
            return 7;

        return 6;
    }
    readonly property string compactTitle: {
        if (showGreenDot)
            return "";

        if (activeMode === 2)
            return notificationTitle || Tr.t("Notification");

        if (activeMode === 5)
            return jobsCount > 0 ? Tr.t("Download active") : Tr.t("Downloads");

        if (activeMode === 7)
            return Tr.t("Sharing screen");

        if (activeMode === 8)
            return buildLabel || (buildSuccess ? Tr.t("Build succeeded") : Tr.t("Build failed"));

        return "";
    }
    property int modeIndex: 0
    property bool logView: false
    property var todayEntries: []
    property int logSeq: 0
    property bool popupOpen: false
    property int unreadCount: 0
    property int jobsCount: 0
    property int jobsPercent: 0
    property date currentTime: new Date()
    property string notificationTitle: ""
    property string notificationBody: ""
    property string notificationIcon: "notifications"
    property string notificationApp: ""
    property var notificationActionNames: []
    property var notificationActionLabels: []
    property bool notificationHasDefaultAction: false
    property bool buildSuccess: true
    property string buildLabel: ""
    property string buildApp: ""

    function dur(ms) {
        return animationsEnabled ? Math.round(ms * animMultiplier) : 0;
    }

    function withAlpha(hex, percent) {
        const c = Qt.lighter(hex, 1);
        return Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(100, percent)) / 100);
    }

    function runExternal(command) {
        executableSource.connectSource(command);
    }

    // Shared by the model-change handler and the live "notification added" signal.
    function applyNotification(item) {
        notificationApp = item.applicationName || "";
        notificationTitle = item.summary || notificationApp || Tr.t("Notification");
        notificationBody = item.body || item.text || "";
        notificationIcon = item.applicationIconName || item.iconName || "notifications";
        notificationActionNames = item.actionNames || [];
        notificationActionLabels = item.actionLabels || [];
        notificationHasDefaultAction = item.hasDefaultAction || false;
    }

    function dismissNotification() {
        if (unreadCount > 0)
            notificationsModel.close(notificationsModel.index(0, 0));

        notificationPulse.stop();
    }

    // Activates the notification's default action — usually raising or opening the
    // source application. No-op when the notification doesn't declare one.
    function activateNotification() {
        if (notificationHasDefaultAction)
            notificationsModel.invokeDefaultAction(notificationsModel.index(0, 0));

        closePopup();
    }

    function invokeNotificationAction(i) {
        const names = notificationActionNames;
        if (i < 0 || i >= names.length)
            return ;

        notificationsModel.invokeAction(notificationsModel.index(0, 0), names[i]);
        closePopup();
    }

    function handleBuildNotification(app, summary, body) {
        if (!Plasmoid.configuration.ideBuildEnabled)
            return false;

        const hay = (app + " " + summary + " " + body).toLowerCase();
        const fromIde = hay.indexOf("intellij") !== -1 || hay.indexOf("idea") !== -1 || hay.indexOf("jetbrains") !== -1 || hay.indexOf("android studio") !== -1 || hay.indexOf("gradle") !== -1 || hay.indexOf("maven") !== -1;
        const aboutBuild = hay.indexOf("build") !== -1 || hay.indexOf("jar") !== -1 || hay.indexOf("compil") !== -1 || hay.indexOf("artifact") !== -1 || hay.indexOf("сборк") !== -1;
        if (!fromIde || !aboutBuild)
            return false;

        const failed = hay.indexOf("fail") !== -1 || hay.indexOf("error") !== -1 || hay.indexOf("ошибк") !== -1 || hay.indexOf("unsuccessful") !== -1 || hay.indexOf("не удал") !== -1;
        buildSuccess = !failed;
        buildApp = app || "IntelliJ IDEA";
        buildLabel = summary || (failed ? Tr.t("Build failed") : Tr.t("Build succeeded"));
        buildTimer.restart();
        return true;
    }

    // ---- Notification log: ~/.cache/dynamicIzland/notify.log ----
    // One line per notification: "[yyyy-MM-dd HH:mm:ss] app: title - body".
    function logNotification(app, summary, body) {
        const clean = (v) => {
            return String(v || "").replace(/<[^>]*>/g, "").replace(/[\r\n]+/g, " ").trim();
        };
        const a = clean(app);
        const t = clean(summary);
        const b = clean(body);
        const head = (a && t) ? a + ": " + t : (a || t);
        const line = head + (b ? (head ? " - " : "") + b : "");
        if (line.length === 0)
            return ;

        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss");
        const quoted = ("[" + stamp + "] " + line).replace(/'/g, "'\\''");
        logSeq++;
        executableSource.connectSource("mkdir -p \"$HOME/.cache/dynamicIzland\" && printf '%s\\n' '" + quoted + "' >> \"$HOME/.cache/dynamicIzland/notify.log\" #w" + logSeq);
    }

    function refreshLog() {
        const day = Qt.formatDate(new Date(), "yyyy-MM-dd");
        logSeq++;
        logReader.connectSource("grep -a \"^." + day + " \" \"$HOME/.cache/dynamicIzland/notify.log\" 2>/dev/null; true #r" + logSeq);
    }

    // Newest first.
    function parseLog(out) {
        const lines = (out || "").split("\n");
        const res = [];
        for (let i = lines.length - 1; i >= 0; i--) {
            const m = /^\[\d{4}-\d{2}-\d{2} (\d{2}:\d{2}:\d{2})\] (.*)$/.exec(lines[i]);
            if (m)
                res.push({
                "time": m[1],
                "text": m[2]
            });

        }
        return res;
    }

    function toggleLog() {
        if (popupOpen && logView) {
            closePopup();
            return ;
        }
        refreshLog();
        logView = true;
        openPopup();
    }

    function openPopup() {
        popupCloseTimer.stop();
        popup.visible = true;
        popupOpen = true;
    }

    function closePopup() {
        popupOpen = false;
        popupCloseTimer.restart();
    }

    function togglePopup() {
        if (popupOpen)
            closePopup();
        else
            openPopup();
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // Native hover tooltip showing the full text the compact capsule elides.
    toolTipMainText: {
        if (popupOpen)
            return "";

        if (activeMode === 2)
            return notificationTitle || Tr.t("Notification");

        if (compactTitle.length > 0)
            return compactTitle;

        return showNetSpeed && netSpeedText ? Tr.t("Network speed") : timeText;
    }
    toolTipSubText: {
        if (popupOpen)
            return "";

        if (activeMode === 2)
            return notificationBody || notificationApp || "";

        return idleMode && showNetSpeed ? netSpeedText : "";
    }
    Layout.minimumWidth: compactWidth
    Layout.minimumHeight: compactHeight
    Layout.preferredWidth: compactWidth
    Layout.preferredHeight: compactHeight
    Layout.maximumWidth: compactWidth
    Layout.maximumHeight: compactHeight
    implicitWidth: Layout.preferredWidth
    implicitHeight: Layout.preferredHeight
    onActiveModeChanged: {
        if (animationsEnabled)
            islandPop.restart();

    }

    // Isolated in its own file so an unavailable sensors module can never break
    // the whole widget — the Loader just fails and stats fall back to the clock.
    Loader {
        id: sysLoader

        active: true
        source: "SystemMonitor.qml"
    }

    // Samples only while the idle capsule (or its popup) actually shows the speed.
    Loader {
        id: netLoader

        active: root.showNetSpeed
        source: "NetSpeed.qml"
        onLoaded: item.active = Qt.binding(() => {
            return root.showNetSpeed && (root.idleMode || root.popupOpen);
        })
    }

    FrameAnimation {
        id: fpsMeter

        running: root.showFps
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }

    Timer {
        id: eventTimer

        interval: 3000
    }

    Timer {
        id: notificationPulse

        interval: 15000
    }

    Timer {
        id: buildTimer

        interval: 6000
    }

    Timer {
        id: popupCloseTimer

        interval: 130
        onTriggered: popup.visible = false
    }

    Plasma5Support.DataSource {
        id: executableSource

        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            // A notification was just appended: keep an open log view current.
            if (root.logView && sourceName.indexOf("notify.log") !== -1)
                root.refreshLog();

        }
    }

    Plasma5Support.DataSource {
        id: logReader

        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            root.todayEntries = root.parseLog(data.stdout);
        }
    }

    NotificationManager.Settings {
        id: notificationSettings
    }

    NotificationManager.Notifications {
        id: notificationsModel

        limit: 1
        showExpired: false
        showDismissed: false
        showNotifications: true
        showJobs: true
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        onUnreadNotificationsCountChanged: {
            root.unreadCount = unreadNotificationsCount;
            if (unreadNotificationsCount > 0 && root.enableNotifications)
                notificationPulse.restart();

        }
        onActiveJobsCountChanged: {
            root.jobsCount = activeJobsCount;
            if (activeJobsCount > 0 && root.enableDownloads) {
                root.modeIndex = 5;
                eventTimer.restart();
            }
        }
        onJobsPercentageChanged: root.jobsPercent = jobsPercentage
        Component.onCompleted: {
            root.unreadCount = unreadNotificationsCount;
            root.jobsCount = activeJobsCount;
            root.jobsPercent = jobsPercentage;
        }
    }

    Connections {
        function onNotificationAdded(notification) {
            const app = notification.applicationName || "";
            const summary = notification.summary || "";
            const body = notification.body || notification.text || "";
            root.logNotification(app, summary, body);
            if (root.handleBuildNotification(app, summary, body))
                return ;

            if (!root.enableNotifications)
                return ;

            root.applyNotification(notification);
            notificationPulse.restart();
        }

        target: NotificationManager.Server
    }

    Repeater {
        model: notificationsModel

        Item {
            readonly property string summaryValue: model.summary || ""
            readonly property string bodyValue: model.body || ""
            readonly property string appValue: model.applicationName || ""
            readonly property string appIconValue: model.applicationIconName || ""
            readonly property string iconValue: model.iconName || ""
            readonly property var actionsValue: model.actionNames || []

            visible: false
            Component.onCompleted: root.applyNotification(model)
            onSummaryValueChanged: root.applyNotification(model)
            onBodyValueChanged: root.applyNotification(model)
            onActionsValueChanged: root.applyNotification(model)
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.activeMode === 2)
                    root.dismissNotification();

                return ;
            }
            root.togglePopup();
        }
        onWheel: (wheel) => {
            wheel.accepted = true;
        }
    }

    Rectangle {
        id: island

        anchors.centerIn: parent
        width: root.compactWidth
        height: root.compactHeight
        radius: height / 2
        color: "transparent"
        border.width: 0
        transformOrigin: Item.Center

        SequentialAnimation {
            id: islandPop

            NumberAnimation {
                target: island
                property: "scale"
                to: 1.06
                duration: root.dur(110)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: island
                property: "scale"
                to: 1
                duration: root.dur(170)
                easing.type: Easing.OutBack
            }

        }

        Loader {
            id: compactLoader

            anchors.fill: parent
            sourceComponent: compactContent
            onLoaded: {
                item.opacity = 0;
                item.scale = 0.96;
                compactFade.target = item;
                compactScale.target = item;
                compactFade.restart();
                compactScale.restart();
            }
        }

        NumberAnimation {
            id: compactFade

            property: "opacity"
            to: 1
            duration: root.dur(120)
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: compactScale

            property: "scale"
            to: 1
            duration: root.dur(160)
            easing.type: Easing.OutCubic
        }

        Behavior on color {
            ColorAnimation {
                duration: root.dur(160)
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.dur(140)
                easing.type: Easing.OutCubic
            }

        }

        Behavior on width {
            NumberAnimation {
                duration: root.dur(220)
                easing.type: Easing.OutCubic
            }

        }

    }

    PlasmaCore.Dialog {
        id: popup

        visualParent: root
        location: Plasmoid.location
        visible: false
        x: Math.round((root.compactWidth - root.expandedWidth) / 2)
        y: root.compactHeight + Plasmoid.configuration.popupGap
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.NoBackground
        Component.onCompleted: flags = flags | Qt.WindowStaysOnTopHint
        // Visibility is driven imperatively (openPopup/closePopup). If the window
        // manager hides the dialog itself (e.g. losing focus while switching
        // monitors) reset the open state so it cannot linger on another screen.
        onVisibleChanged: {
            if (!visible) {
                popupCloseTimer.stop();
                root.popupOpen = false;
                root.logView = false;
            }
        }

        mainItem: Item {
            width: root.expandedWidth
            height: root.expandedHeight
            opacity: root.popupOpen ? 1 : 0
            scale: root.popupOpen ? 1 : 0.92

            MouseArea {
                id: popupMouseArea

                anchors.fill: parent
                hoverEnabled: true
                onExited: root.closePopup()
            }

            Rectangle {
                anchors.fill: parent
                radius: root.cornerRadius
                color: root.panelBackground
                border.width: root.borderEnabled && root.backgroundEnabled ? 1 : 0
                border.color: root.borderColor

                Loader {
                    id: expandedLoader

                    anchors.fill: parent
                    sourceComponent: expandedContent
                    onLoaded: {
                        item.opacity = 0;
                        item.scale = 0.97;
                        expandedFade.target = item;
                        expandedScale.target = item;
                        expandedFade.restart();
                        expandedScale.restart();
                    }
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.dur(130)
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: root.dur(170)
                    easing.type: Easing.OutBack
                }

            }

        }

    }

    NumberAnimation {
        id: expandedFade

        property: "opacity"
        to: 1
        duration: root.dur(120)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: expandedScale

        property: "scale"
        to: 1
        duration: root.dur(160)
        easing.type: Easing.OutCubic
    }

    Component {
        id: compactContent

        RowLayout {
            id: compactLayout

            anchors.fill: parent
            anchors.leftMargin: root.compactSidePadding
            anchors.rightMargin: root.compactSidePadding
            spacing: root.moduleSeparators ? 6 : 8

            Repeater {
                model: ["clock", "system", "content"]

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: modelData === "content"
                    Layout.minimumWidth: 0
                    spacing: root.moduleSeparators ? 6 : 8

                    PlasmaComponents.Label {
                        visible: index > 0 && root.moduleSeparators && !(modelData === "content" && root.showGreenDot && !root.showNetSpeed)
                        text: "/"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pointSize: 15
                        font.weight: Font.Light
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Loader {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: modelData === "content"
                        Layout.minimumWidth: 0
                        sourceComponent: modelData === "clock" ? compactClockBlock : modelData === "system" ? compactSystemBlock : compactContentBlock
                    }

                }

            }

        }

    }

    Component {
        id: compactContentBlock

        Item {
            // Small implicit width: the Loader stretches this item to the space left in
            // the fixed-width capsule, and the labels inside elide.
            implicitWidth: 0
            implicitHeight: contentRow.implicitHeight

            // Click the notification area to see today's notification log.
            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: -2
                anchors.rightMargin: -14
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                z: 1
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleLog()
            }

            RowLayout {
                id: contentRow

                anchors.fill: parent
                spacing: 8

                Rectangle {
                    id: sharingDot

                    visible: root.sharingScreen
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    radius: 5
                    color: root.sharingDotColor
                    transformOrigin: Item.Center

                    SequentialAnimation on opacity {
                        running: sharingDot.visible && root.animationsEnabled
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.45
                            duration: root.dur(700)
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: root.dur(700)
                            easing.type: Easing.InOutSine
                        }

                    }

                }

                Rectangle {
                    id: idleDot

                    visible: root.showGreenDot
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    radius: 5
                    color: root.idleDotColor
                    transformOrigin: Item.Center

                    SequentialAnimation on scale {
                        running: root.showGreenDot && root.animationsEnabled
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 1.35
                            duration: root.dur(900)
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: root.dur(900)
                            easing.type: Easing.InOutSine
                        }

                    }

                    SequentialAnimation on opacity {
                        running: root.showGreenDot && root.animationsEnabled
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.55
                            duration: root.dur(900)
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: root.dur(900)
                            easing.type: Easing.InOutSine
                        }

                    }

                }

                StatusIcon {
                    visible: !root.showGreenDot
                    mode: root.activeMode
                    iconName: root.notificationIcon
                    unread: root.unreadCount
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }

                PlasmaComponents.Label {
                    text: root.compactTitle
                    visible: !root.showGreenDot && text.length > 0
                    color: root.textPrimary
                    font.pointSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                // Idle: no notification pending, so show live network speed instead.
                PlasmaComponents.Label {
                    visible: root.showGreenDot && root.showNetSpeed
                    text: root.netSpeedStyled
                    textFormat: Text.StyledText
                    font.family: Kirigami.Theme.fixedFont.family
                    font.pointSize: 12
                    font.weight: Font.Medium
                    color: root.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Rectangle {
                    id: unreadBadge

                    visible: root.activeMode === 2 && root.unreadCount > 0
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 6
                    color: root.accent
                    transformOrigin: Item.Center

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: root.unreadCount
                        color: "white"
                        font.bold: true
                    }

                    SequentialAnimation on scale {
                        running: unreadBadge.visible && notificationPulse.running && root.animationsEnabled
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 1.18
                            duration: root.dur(520)
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            to: 1
                            duration: root.dur(520)
                            easing.type: Easing.InCubic
                        }

                    }

                }

            }

        }

    }

    Component {
        id: compactClockBlock

        Item {
            implicitWidth: clockLabel.implicitWidth
            implicitHeight: clockLabel.implicitHeight

            PlasmaComponents.Label {
                id: clockLabel

                anchors.fill: parent
                text: root.timeText
                color: root.textPrimary
                font.pointSize: 16
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runExternal("/usr/bin/korganizer")
            }

        }

    }

    Component {
        id: compactSystemBlock

        Item {
            implicitWidth: systemLayout.implicitWidth
            implicitHeight: systemLayout.implicitHeight

            RowLayout {
                id: systemLayout

                anchors.fill: parent
                spacing: 6

                PlasmaComponents.Label {
                    id: systemLabel

                    text: root.statsText.length > 0 ? root.statsText : Tr.t("System")
                    color: root.textPrimary
                    font.pointSize: 16
                    font.weight: Font.Medium
                }

                PlasmaComponents.Label {
                    text: root.fps + " fps"
                    visible: root.showFps
                    color: root.fpsStyle === "plain" ? root.textPrimary : root.accent
                    font.pointSize: root.fpsStyle === "plain" ? 16 : 9
                    font.weight: root.fpsStyle === "plain" ? Font.Medium : Font.Bold
                }

            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runExternal("/usr/bin/xfce4-taskmanager")
            }

        }

    }

    Component {
        id: expandedContent

        Item {
            anchors.fill: parent

            Loader {
                anchors.fill: parent
                sourceComponent: {
                    if (root.logView)
                        return notificationLog;

                    if (root.activeMode === 2)
                        return notificationExpanded;

                    return statusExpanded;
                }
            }

        }

    }

    Component {
        id: notificationLog

        Item {
            anchors.fill: parent

            RowLayout {
                id: logHeader

                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: Tr.t("Today's notifications")
                    color: root.textPrimary
                    font.pointSize: 13
                    font.weight: Font.Medium
                }

                PlasmaComponents.Label {
                    text: root.todayEntries.length
                    color: root.accent
                    font.pointSize: 11
                    font.weight: Font.Bold
                }

            }

            ListView {
                id: logList

                anchors.top: logHeader.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                clip: true
                spacing: 6
                model: root.todayEntries
                boundsBehavior: Flickable.StopAtBounds

                PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                }

                delegate: RowLayout {
                    width: ListView.view.width
                    spacing: 10

                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignTop
                        text: modelData.time
                        color: root.accent
                        font.pointSize: 10
                        font.weight: Font.Bold
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        text: modelData.text
                        color: root.textPrimary
                        font.pointSize: 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                }

            }

            PlasmaComponents.Label {
                anchors.centerIn: logList
                visible: root.todayEntries.length === 0
                text: Tr.t("No notifications today")
                color: root.textSecondary
                font.pointSize: 11
            }

        }

    }

    Component {
        id: notificationExpanded

        Item {
            id: notifRoot

            readonly property bool hasActions: root.notificationActionLabels.length > 0

            anchors.fill: parent

            StatusIcon {
                id: notifIcon

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                mode: 2
                iconName: root.notificationIcon
                unread: root.unreadCount
            }

            Column {
                anchors.left: notifIcon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.top: parent.top
                anchors.topMargin: notifRoot.hasActions ? 12 : 0
                anchors.verticalCenter: notifRoot.hasActions ? undefined : parent.verticalCenter
                spacing: 3

                PlasmaComponents.Label {
                    width: parent.width
                    text: root.notificationTitle || Tr.t("Notification")
                    color: root.textPrimary
                    font.pointSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                PlasmaComponents.Label {
                    width: parent.width
                    text: root.notificationBody || root.notificationApp || (root.unreadCount > 0 ? Tr.tr("%1 unread", root.unreadCount) : Tr.t("New notification"))
                    color: root.textSecondary
                    font.pointSize: 10
                    wrapMode: Text.WordWrap
                    maximumLineCount: notifRoot.hasActions ? 1 : Plasmoid.configuration.notificationBodyLines
                    elide: Text.ElideRight
                }

            }

            // Click the icon/text region to trigger the default action (open the app).
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: notifRoot.hasActions ? notifActions.top : parent.bottom
                enabled: root.notificationHasDefaultAction
                onClicked: root.activateNotification()
            }

            Row {
                id: notifActions

                visible: notifRoot.hasActions
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                spacing: 8

                Repeater {
                    model: Math.min(2, root.notificationActionLabels.length)

                    ActionPill {
                        label: root.notificationActionLabels[index] || ""
                        onTriggered: root.invokeNotificationAction(index)
                    }

                }

            }

        }

    }

    Component {
        id: statusExpanded

        Item {
            id: statusRoot

            readonly property bool hasProgress: root.activeMode === 5 || root.activeMode === 8

            anchors.fill: parent

            StatusIcon {
                id: statusIcon

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                mode: root.activeMode
                iconName: root.notificationIcon
                unread: root.unreadCount
            }

            Column {
                anchors.left: statusIcon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                PlasmaComponents.Label {
                    width: parent.width
                    text: root.activeMode === 6 && root.showNetSpeed ? Tr.t("Network speed") : root.compactTitle
                    color: root.textPrimary
                    font.pointSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                PlasmaComponents.Label {
                    width: parent.width
                    text: root.activeMode === 6 && root.showNetSpeed ? root.netSpeedText : root.activeMode === 4 ? Tr.t("Pomodoro session in progress") : root.activeMode === 5 ? (root.jobsCount > 0 ? Tr.tr("%1% complete", root.jobsPercent) : Tr.t("No active downloads")) : root.activeMode === 7 ? Tr.t("Active capture or presentation mode") : root.activeMode === 8 ? (root.buildApp + (root.buildSuccess ? " · " + Tr.t("success") : " · " + Tr.t("failed"))) : Tr.t("Status")
                    color: root.textSecondary
                    font.pointSize: 10
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: statusRoot.hasProgress
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.18)

                    Rectangle {
                        width: parent.width * (root.activeMode === 8 ? (root.buildSuccess ? 1 : 0.4) : root.jobsPercent > 0 ? root.jobsPercent / 100 : 0.05)
                        height: parent.height
                        radius: parent.radius
                        color: root.activeMode === 8 ? (root.buildSuccess ? "#55e36a" : "#ff4f6f") : root.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: root.dur(260)
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

    }

    component StatusIcon: Item {
        property int mode: 0
        property int unread: 0
        property string iconName: "notifications"

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: mode === 1 ? Qt.rgba(0.35, 0.42, 0.52, 0.35) : mode === 2 ? "#2da6e8" : mode === 4 ? "#e84855" : mode === 5 ? Qt.rgba(0.12, 0.6, 0.95, 0.34) : mode === 6 ? Qt.rgba(0.2, 0.9, 0.35, 0.24) : mode === 7 ? Qt.rgba(0.25, 1, 0.15, 0.28) : mode === 8 ? (root.buildSuccess ? Qt.rgba(0.33, 0.89, 0.41, 0.3) : Qt.rgba(0.92, 0.3, 0.36, 0.32)) : Qt.rgba(0.55, 0.4, 1, 0.3)

            Behavior on color {
                ColorAnimation {
                    duration: root.dur(160)
                }

            }

        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: parent.width * 0.62
            height: width
            source: mode === 1 ? "audio-volume-high" : mode === 2 ? iconName : mode === 4 ? "chronometer" : mode === 5 ? "download" : mode === 6 ? "security-high" : mode === 7 ? "krfb" : mode === 8 ? (root.buildSuccess ? "emblem-success" : "emblem-error") : "utilities-terminal"
        }

    }

    component ActionPill: Rectangle {
        property string label: ""

        signal triggered()

        height: 26
        width: pillLabel.implicitWidth + 24
        radius: height / 2
        color: pillMouse.pressed ? Qt.lighter(root.accent, 1.15) : root.accent

        PlasmaComponents.Label {
            id: pillLabel

            anchors.centerIn: parent
            text: parent.label
            color: "white"
            font.pointSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        MouseArea {
            id: pillMouse

            anchors.fill: parent
            onClicked: parent.triggered()
        }

        Behavior on color {
            ColorAnimation {
                duration: root.dur(120)
            }

        }

    }

}