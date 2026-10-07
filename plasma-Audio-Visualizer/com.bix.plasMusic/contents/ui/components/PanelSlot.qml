import QtQuick
import QtQuick.Layouts

// One box in the panel row. fixedWidth > 0 pins the box width (content is
// centered in it); 0 = follow the content. slotMargin is the outer margin.
Item {
    id: slot

    property bool horizontal: true
    property int fixedWidth: 0
    property int slotMargin: 0
    property real autoSize: 0
    default property alias content: holder.data

    readonly property real size: fixedWidth > 0 ? fixedWidth : autoSize

    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    Layout.fillHeight: horizontal
    Layout.fillWidth: !horizontal
    Layout.leftMargin: horizontal ? slotMargin : 0
    Layout.rightMargin: horizontal ? slotMargin : 0
    Layout.topMargin: horizontal ? 0 : slotMargin
    Layout.bottomMargin: horizontal ? 0 : slotMargin
    Layout.preferredWidth: horizontal ? size : -1
    Layout.preferredHeight: horizontal ? -1 : size
    implicitWidth: horizontal ? size : 0
    implicitHeight: horizontal ? 0 : size

    Item {
        id: holder

        anchors.fill: parent
    }
}
