import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    width: 310
    height: 250
    radius: 18
    color: Qt.rgba(0.08, 0.09, 0.11, 0.75)
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    property var tasks: []
    property int totalCount: tasks.length
    property int completedCount: {
        var c = 0
        for (var i = 0; i < tasks.length; i++) {
            if (tasks[i] && tasks[i].done) c++
        }
        return c
    }

    function loadTasks() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../data/todos.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (Array.isArray(data)) {
                            // Sort: pending first, then completed
                            var sorted = data.slice().sort(function(a, b) {
                                if (!!a.done !== !!b.done) {
                                    return a.done ? 1 : -1
                                }
                                return (b.createdAt || 0) - (a.createdAt || 0)
                            })
                            root.tasks = sorted
                        }
                    } catch (e) {
                        console.warn("SDDM TodoList error:", e)
                    }
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: loadTasks()

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.loadTasks()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header
        Item {
            width: parent.width
            height: 26

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Image {
                    source: Qt.resolvedUrl("../icons/checklist.svg")
                    width: 18
                    height: 18
                    sourceSize: Qt.size(18, 18)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Tareas"
                    color: "#f0f6fc"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    height: 18
                    width: countText.implicitWidth + 12
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.08)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.completedCount + "/" + root.totalCount
                        color: "#8b949e"
                        font.pixelSize: 10
                        font.bold: true
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        // List of tasks
        ListView {
            id: taskListView
            width: parent.width
            height: parent.height - 36
            clip: true
            spacing: 5
            model: root.tasks
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: taskListView.width
                height: 34
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    // Checkbox
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 4
                        color: modelData.done ? "#238636" : Qt.rgba(1, 1, 1, 0.06)
                        border.color: modelData.done ? "#3fb950" : Qt.rgba(1, 1, 1, 0.3)
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl("../icons/check.svg")
                            width: 11
                            height: 11
                            sourceSize: Qt.size(11, 11)
                            visible: modelData.done
                        }
                    }

                    // Task text
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        text: modelData.text || ""
                        color: modelData.done ? "#6e7681" : "#f0f6fc"
                        font.pixelSize: 12
                        font.strikeout: modelData.done
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Empty state
            Item {
                anchors.centerIn: parent
                visible: root.totalCount === 0
                width: parent.width
                height: 60

                Text {
                    anchors.centerIn: parent
                    text: "No hay tareas registradas"
                    color: "#8b949e"
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
