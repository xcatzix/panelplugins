import QtQuick
import QtQuick.Layouts

// Clickable image button (used for the panel playback controls).
Item {
    id: container

    property int size: 16
    property url source
    signal clicked()

    Layout.preferredWidth: size
    Layout.preferredHeight: size
    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        source: container.source
        sourceSize: Qt.size(container.size * 2, container.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: mouse.containsMouse ? 1 : 0.85
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: container.clicked()
    }
}
