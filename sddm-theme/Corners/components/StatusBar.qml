import QtQuick 2.15

Item {
    id: root
    width: statusRow.implicitWidth
    height: 30

    property string dateStr: ""

    function updateStatus() {
        var now = new Date()
        root.dateStr = now.toLocaleDateString(Qt.locale("es_ES"), "ddd d 'de' MMM")
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.updateStatus()
    }

    Component.onCompleted: root.updateStatus()

    Row {
        id: statusRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Rectangle {
            height: 26
            width: dateText.implicitWidth + 16
            radius: 13
            color: Qt.rgba(0.08, 0.09, 0.11, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            Text {
                id: dateText
                anchors.centerIn: parent
                text: root.dateStr
                color: "#c9d1d9"
                font.pixelSize: 11
                font.bold: true
                renderType: Text.NativeRendering
            }
        }
    }
}
