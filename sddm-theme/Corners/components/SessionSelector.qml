import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property int sessionIndex: 0
    property string currentSessionName: "Niri"

    width: sessRow.implicitWidth + 30
    height: 40

    // Safely scan sessionModel to prioritize niri
    ListView {
        id: sessionScanner
        visible: false
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        delegate: Item {
            Component.onCompleted: {
                if (model.name && model.name.toLowerCase().indexOf("niri") !== -1) {
                    root.sessionIndex = index
                    root.currentSessionName = model.name
                } else if (index === (sessionModel.lastIndex || 0) && root.currentSessionName === "Niri") {
                    root.sessionIndex = index
                    root.currentSessionName = model.name
                }
            }
        }
    }

    Rectangle {
        id: sessPill
        anchors.fill: parent
        radius: 20
        color: sessArea.containsMouse ? Qt.rgba(0.14, 0.16, 0.20, 0.9) : Qt.rgba(0.08, 0.09, 0.11, 0.78)
        border.color: sessArea.containsMouse ? "#3fb950" : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1.2

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: sessRow
            anchors.centerIn: parent
            spacing: 8

            Image {
                source: Qt.resolvedUrl("../icons/settings.svg")
                width: 18
                height: 18
                sourceSize: Qt.size(18, 18)
                anchors.verticalCenter: parent.verticalCenter
                smooth: true
            }

            Text {
                text: root.currentSessionName
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            id: sessArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sessPopup.visible ? sessPopup.close() : sessPopup.open()
        }
    }

    Popup {
        id: sessPopup
        x: parent.width - width
        y: -height - 8
        width: 180
        padding: 8

        background: Rectangle {
            radius: 14
            color: Qt.rgba(0.08, 0.09, 0.11, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        contentItem: ListView {
            id: sessionList
            implicitHeight: Math.min(contentHeight, 200)
            spacing: 4
            clip: true
            model: typeof sessionModel !== "undefined" ? sessionModel : null

            delegate: Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: (sessionItemArea.containsMouse || index === root.sessionIndex) ? Qt.rgba(0.25, 0.73, 0.31, 0.2) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: model.name || ""
                    color: index === root.sessionIndex ? "#3fb950" : "#f0f6fc"
                    font.pixelSize: 12
                    font.bold: index === root.sessionIndex
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: sessionItemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionIndex = index
                        root.currentSessionName = model.name
                        sessPopup.close()
                    }
                }
            }
        }
    }
}
