import QtQuick 2.15

Item {
    id: root
    width: clockRow.implicitWidth
    height: clockRow.implicitHeight

    property string hoursText: "12"
    property string minutesText: "00"
    property string dateText: ""

    function updateTime() {
        var now = new Date()
        var h = now.getHours() % 12
        if (h === 0) h = 12
        var m = now.getMinutes()
        root.hoursText = h.toString() + ":"
        root.minutesText = (m < 10 ? "0" : "") + m.toString()

        var options = { weekday: 'short', day: 'numeric', month: 'short' }
        root.dateText = now.toLocaleDateString(Qt.locale("es_ES"), "ddd d 'de' MMMM")
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.updateTime()
    }

    Component.onCompleted: root.updateTime()

    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        Row {
            id: clockRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Text {
                text: root.hoursText
                color: "#ffffff"
                font.pixelSize: 110
                font.weight: Font.Black
                font.family: "Inter, Cantarell, Roboto, sans-serif"
                renderType: Text.NativeRendering
            }

            Text {
                text: root.minutesText
                color: "#3fb950"
                font.pixelSize: 110
                font.weight: Font.Black
                font.family: "Inter, Cantarell, Roboto, sans-serif"
                renderType: Text.NativeRendering
            }
        }
    }
}
