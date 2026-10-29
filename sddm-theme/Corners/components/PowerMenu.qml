import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 44
    height: 44

    Rectangle {
        id: powerBtn
        anchors.fill: parent
        radius: 14
        color: powerArea.containsPress ? "#88c2a8" : (powerArea.containsMouse ? "#b2e4ce" : "#9fd5be")
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Image {
            anchors.centerIn: parent
            source: Qt.resolvedUrl("../icons/power.svg")
            width: 22
            height: 22
            sourceSize: Qt.size(22, 22)
            smooth: true
        }

        MouseArea {
            id: powerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: powerPopup.visible ? powerPopup.close() : powerPopup.open()
        }
    }

    Popup {
        id: powerPopup
        x: 0
        y: -140
        width: 150
        height: 130
        padding: 6

        background: Rectangle {
            radius: 14
            color: Qt.rgba(0.08, 0.09, 0.11, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        contentItem: Column {
            spacing: 4
            anchors.fill: parent

            // Sleep
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: sleepArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        source: Qt.resolvedUrl("../icons/sleep.svg")
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Suspender"
                        color: "#f0f6fc"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    id: sleepArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { powerPopup.close(); sddm.suspend() }
                }
            }

            // Reboot
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: rebootArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        source: Qt.resolvedUrl("../icons/restart.svg")
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Reiniciar"
                        color: "#f0f6fc"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    id: rebootArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { powerPopup.close(); sddm.reboot() }
                }
            }

            // Power off
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: shutdownArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.25) : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        source: Qt.resolvedUrl("../icons/power.svg")
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Apagar"
                        color: "#ff7b72"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    id: shutdownArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { powerPopup.close(); sddm.powerOff() }
                }
            }
        }
    }
}
