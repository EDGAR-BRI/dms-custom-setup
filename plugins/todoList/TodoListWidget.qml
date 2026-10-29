import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    property real widgetWidth: 320
    property real widgetHeight: 280
    property real defaultWidth: 320
    property real defaultHeight: 280
    property real minWidth: 260
    property real minHeight: 180
    property string instanceId: ""
    property var instanceData: null
    property bool lockScreen: false
    property var lockHost: null
    property var screen: null
    property var pluginService: null
    property string pluginId: ""
    property bool acceptsKeyboardFocus: !lockScreen

    property var tasks: []
    property string lastSaved: ""

    readonly property int totalCount: tasks ? tasks.length : 0
    readonly property int completedCount: {
        if (!tasks) return 0;
        let c = 0;
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i] && tasks[i].done) c++;
        }
        return c;
    }
    readonly property int pendingCount: totalCount - completedCount
    readonly property string todosFilePath: Paths.strip(Paths.state) + "/todos.json"

    function sortTasks(taskList) {
        if (!taskList || !Array.isArray(taskList)) return [];
        return taskList.slice().sort((a, b) => {
            if (!!a.done !== !!b.done) {
                return a.done ? 1 : -1;
            }
            return (b.createdAt || 0) - (a.createdAt || 0);
        });
    }

    function loadTasks(content) {
        if (!content || !content.trim()) return;
        try {
            const data = JSON.parse(content);
            if (Array.isArray(data)) {
                root.tasks = sortTasks(data);
            }
        } catch (e) {
            console.warn("TodoList: Error parsing todos.json", e);
        }
    }

    function saveTasks(newTasks) {
        const sorted = sortTasks(newTasks);
        root.tasks = sorted;
        const jsonStr = JSON.stringify(sorted, null, 2) + "\n";
        root.lastSaved = jsonStr;
        todoFile.setText(jsonStr);
        try {
            sddmTodoFile.setText(jsonStr);
        } catch (e) {}
    }

    function addTask(text) {
        const trimmed = (text || "").trim();
        if (!trimmed) return;
        const newTask = {
            id: Date.now().toString(36) + Math.random().toString(36).substring(2, 6),
            text: trimmed,
            done: false,
            createdAt: Date.now()
        };
        const current = root.tasks ? root.tasks.slice() : [];
        current.unshift(newTask);
        saveTasks(current);
    }

    function toggleTask(id) {
        if (!root.tasks) return;
        const current = root.tasks.map(t => {
            if (t.id === id) {
                return {
                    id: t.id,
                    text: t.text,
                    done: !t.done,
                    createdAt: t.createdAt || Date.now()
                };
            }
            return t;
        });
        saveTasks(current);
    }

    function deleteTask(id) {
        if (root.lockScreen) return;
        if (!root.tasks) return;
        const current = root.tasks.filter(t => t.id !== id);
        saveTasks(current);
    }

    function clearCompleted() {
        if (root.lockScreen) return;
        if (!root.tasks) return;
        const current = root.tasks.filter(t => !t.done);
        saveTasks(current);
    }

    FileView {
        id: todoFile
        path: root.todosFilePath
        watchChanges: true
        blockWrites: true
        atomicWrites: true
        onLoaded: {
            const raw = text();
            if (raw === root.lastSaved) return;
            root.loadTasks(raw);
            try {
                sddmTodoFile.setText(raw);
            } catch (e) {}
        }
        onFileChanged: reload()
    }

    FileView {
        id: sddmTodoFile
        path: "/usr/share/sddm/themes/Corners/data/todos.json"
        blockWrites: true
        atomicWrites: true
    }

    Component.onCompleted: {
        todoFile.reload();
    }

    // Glass Card Container
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(0.08, 0.09, 0.11, 0.72)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        Item {
            id: innerContent
            anchors.fill: parent
            anchors.margins: 14

            // Header
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 26

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    DIcon {
                        name: "checklist"
                        size: 20
                        color: "#3fb950"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Tareas"
                        color: "#f0f6fc"
                        font.pixelSize: 13
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Count Badge
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        width: badgeText.implicitWidth + 12
                        radius: 10
                        color: root.pendingCount === 0 && root.totalCount > 0 
                               ? Qt.rgba(0.25, 0.73, 0.31, 0.2) 
                               : Qt.rgba(1, 1, 1, 0.08)
                        border.color: root.pendingCount === 0 && root.totalCount > 0 
                                      ? Qt.rgba(0.25, 0.73, 0.31, 0.4) 
                                      : Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: root.totalCount === 0 ? "0" : (root.completedCount + "/" + root.totalCount)
                            color: root.pendingCount === 0 && root.totalCount > 0 ? "#3fb950" : "#c9d1d9"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // Header Action: Clear Completed (Desktop only)
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 6
                    visible: !root.lockScreen && root.completedCount > 0
                    color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                    DIcon {
                        anchors.centerIn: parent
                        name: "delete_sweep"
                        size: 16
                        color: clearMouse.containsMouse ? "#ff7b72" : "#8b949e"
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearCompleted()
                    }
                }
            }

            // Input field (Desktop only)
            Rectangle {
                id: inputRow
                anchors.top: header.bottom
                anchors.topMargin: root.lockScreen ? 0 : 10
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.lockScreen ? 0 : 34
                visible: !root.lockScreen
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: taskInput.activeFocus ? "#3fb950" : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                TextInput {
                    id: taskInput
                    anchors.left: parent.left
                    anchors.right: addBtn.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    color: "#f0f6fc"
                    font.pixelSize: 12
                    selectByMouse: true
                    clip: true
                    activeFocusOnTab: true
                    onAccepted: {
                        if (text.trim().length > 0) {
                            root.addTask(text);
                            text = "";
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: "Agregar tarea... (Enter)"
                        color: "#6e7681"
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        visible: !taskInput.text && !taskInput.activeFocus
                    }
                }

                Rectangle {
                    id: addBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 6
                    color: addArea.containsMouse ? "#2ea043" : "#238636"
                    opacity: taskInput.text.trim().length > 0 ? 1.0 : 0.45

                    DIcon {
                        anchors.centerIn: parent
                        name: "add"
                        size: 16
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (taskInput.text.trim().length > 0) {
                                root.addTask(taskInput.text);
                                taskInput.text = "";
                            }
                        }
                    }
                }
            }

            // Task List
            ListView {
                id: tasksListView
                anchors.top: inputRow.visible ? inputRow.bottom : header.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                spacing: 5
                model: root.tasks
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: taskDelegate
                    required property var modelData
                    required property int index

                    width: tasksListView.width
                    height: 36
                    radius: 8
                    color: itemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                    border.color: itemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTask(modelData.id)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 10

                        // Checkbox
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 5
                            color: modelData.done ? "#238636" : Qt.rgba(1, 1, 1, 0.05)
                            border.color: modelData.done ? "#3fb950" : Qt.rgba(1, 1, 1, 0.3)
                            border.width: 1.5

                            DIcon {
                                anchors.centerIn: parent
                                name: "check"
                                size: 13
                                color: "#ffffff"
                                visible: modelData.done
                            }
                        }

                        // Task Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.lockScreen ? (parent.width - 18 - 10) : (parent.width - 18 - 10 - 24 - 10)
                            text: modelData.text || ""
                            color: modelData.done ? "#6e7681" : "#f0f6fc"
                            font.pixelSize: 12
                            font.strikeout: modelData.done
                            elide: Text.ElideRight
                        }

                        // Delete button (Desktop only, hidden on lockscreen)
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            visible: !root.lockScreen

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: delArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.25) : "transparent"
                            }

                            DIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 14
                                color: delArea.containsMouse ? "#ff7b72" : "#6e7681"
                            }

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteTask(modelData.id)
                            }
                        }
                    }
                }
            }

            // Empty state message
            Item {
                anchors.centerIn: tasksListView
                visible: root.totalCount === 0
                width: parent.width
                height: 80

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    DIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "task_alt"
                        size: 26
                        color: "#484f58"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "¡No tienes tareas pendientes!"
                        color: "#8b949e"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
