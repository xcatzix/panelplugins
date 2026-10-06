import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Scrollable lyrics list shown in the floating window opened from the panel.
// Size, padding and corner radius come from the settings.
// Right-click re-downloads the lyrics of the current track.
Item {
    id: view

    property var provider
    readonly property var cfg: plasmoid.configuration

    implicitWidth: cfg.lyricsWindowWidth
    implicitHeight: cfg.lyricsWindowHeight
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    function followCurrent() {
        if (provider && provider.currentIndex >= 0 && !list.moving && !list.dragging)
            list.positionViewAtIndex(provider.currentIndex, ListView.Center);
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(cfg.lyricsWindowRadius / 100 * Math.min(width, height) / 2)
        color: Kirigami.Theme.backgroundColor
        border.width: cfg.lyricsWindowBorderWidth
        border.color: cfg.lyricsWindowBorderColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: cfg.lyricsWindowPadding
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.bold: true
            color: Kirigami.Theme.textColor
            text: view.provider ? (view.provider.artist ? view.provider.title + " — " + view.provider.artist : view.provider.title) : ""
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.separatorColor
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: view.provider ? view.provider.lines : []
            Controls.ScrollBar.vertical: Controls.ScrollBar {
            }

            delegate: Controls.Label {
                required property var modelData
                required property int index
                readonly property bool current: view.provider && view.provider.timed && index === view.provider.currentIndex

                width: Math.max(10, list.width - 14)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                text: modelData.text
                clip: true
                font.bold: current
                color: current ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                opacity: current || !(view.provider && view.provider.timed) ? 1 : 0.65
            }

            Controls.Label {
                anchors.centerIn: parent
                visible: list.count === 0
                color: Kirigami.Theme.disabledTextColor
                text: view.provider && view.provider.status === "loading" ? i18n("Loading lyrics…") : i18n("No lyrics found")
            }
        }
    }

    Connections {
        function onCurrentIndexChanged() {
            view.followCurrent();
        }

        target: view.provider
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: if (view.provider) view.provider.reload(true)
    }

    onVisibleChanged: if (visible) Qt.callLater(followCurrent)
    Component.onCompleted: Qt.callLater(followCurrent)
}
