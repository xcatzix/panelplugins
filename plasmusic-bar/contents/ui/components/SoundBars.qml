import QtQuick 2.15
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool playing: false
    property int barCount: 5
    property real barWidth: 2.5
    property real barHeight: 16
    property real barSpacing: 2
    property color color: Kirigami.Theme.textColor

    implicitWidth: row.implicitWidth
    implicitHeight: barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.barSpacing
        height: root.barHeight

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar
                width: root.barWidth
                radius: width / 2
                color: root.color
                opacity: root.playing ? 1.0 : 0.45
                anchors.verticalCenter: parent.verticalCenter

                readonly property real baseHeight: root.barHeight * [0.55, 0.8, 1.0, 0.7, 0.9, 0.65, 0.85, 0.6][index % 8]
                property real animationScale: 1.0
                height: baseHeight * (root.playing ? animationScale : 0.55)

                SequentialAnimation on animationScale {
                    running: root.playing
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.45 + (index % 3) * 0.12
                        to: 1.0
                        duration: 180 + index * 45
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: 1.0
                        to: 0.45 + (index % 3) * 0.12
                        duration: 180 + index * 45
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
