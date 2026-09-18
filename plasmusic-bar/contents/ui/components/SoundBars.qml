import QtQuick 2.15
import org.kde.kirigami as Kirigami

// SoundBars - 音频跳动条
// 播放时做正弦波起伏动画，暂停/停止时静止并降低透明度。
// playing: bool   - 是否处于播放状态（绑定 player.playbackStatus 即可）
// barCount: int   - 跳动的柱子数量（默认 5）
// barWidth: real  - 单根柱子宽度（默认 2.5）
// barHeight: real - 柱子基准高度（默认 16，错落在此基础上变化）
// spacing: real   - 柱子间距（默认 2）
Item {
    id: root

    property bool playing: false
    property int barCount: 5
    property real barWidth: 2.5
    property real barHeight: 16
    property real barSpacing: 2

    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: parent.height > 0 ? parent.height : Kirigami.Units.iconSizes.medium

    // 点击跳动条 = 播放/暂停（与播放按钮等效）
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Row {
        id: row

        spacing: root.barSpacing
        // 优先使用 barHeight 作为行高，避免父项高度为 0 时跳动条不可见
        height: root.barHeight > 0 ? root.barHeight : parent.height

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar

                // 每根柱子一个高度系数，制造错落感
                readonly property var _factors: [0.75, 1.15, 0.6, 1, 0.85, 0.7, 1.1, 0.65]

                width: root.barWidth
                height: root.barHeight * _factors[index % _factors.length]
                y: (parent.height - height) / 2
                radius: root.barWidth / 2
                color: Kirigami.Theme.textColor
                opacity: root.playing ? 0.9 : 0.4
                transformOrigin: Item.Center

                transform: Scale {
                    origin.x: bar.width / 2
                    origin.y: bar.height / 2
                    yScale: root.playing ? 1 : 0.5

                    SequentialAnimation on yScale {
                        running: root.playing
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.3 + ((index * 13) % 40) / 100
                            duration: 220 + index * 40
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 220 + index * 40
                            easing.type: Easing.InOutSine
                        }

                    }

                }

            }

        }

    }

}
