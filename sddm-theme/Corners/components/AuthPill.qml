import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12

Item {
    id: root

    width: authRow.implicitWidth
    height: 46

    property string currentUser: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : "edgar"
    property int currentSession: (typeof sessionModel !== "undefined" && sessionModel.lastIndex !== undefined) ? sessionModel.lastIndex : 0
    property bool isAuthenticating: false
    property bool hasFailed: false

    signal userClicked()

    function submitLogin() {
        if (root.isAuthenticating) return
        root.isAuthenticating = true
        root.hasFailed = false
        sddm.login(root.currentUser, passwordField.text, root.currentSession)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.isAuthenticating = false
            root.hasFailed = true
            passwordField.text = ""
            shakeAnim.start()
            resetFailTimer.start()
        }
        function onLoginSucceeded() {
            root.isAuthenticating = true
        }
    }

    Timer {
        id: resetFailTimer
        interval: 1500
        repeat: false
        onTriggered: root.hasFailed = false
    }

    SequentialAnimation {
        id: shakeAnim
        loops: 2
        NumberAnimation { target: authRow; property: "x"; to: authRow.x - 8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: authRow; property: "x"; to: authRow.x + 8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: authRow; property: "x"; to: authRow.x; duration: 50; easing.type: Easing.InOutQuad }
    }

    Row {
        id: authRow
        spacing: 12
        anchors.centerIn: parent

        // User Avatar Circle Button (perfect circular mask)
        Item {
            width: 46
            height: 46

            Rectangle {
                id: userBg
                anchors.fill: parent
                radius: 23
                color: Qt.rgba(0.08, 0.09, 0.11, 0.85)
                border.color: userMouseArea.containsMouse ? "#3fb950" : Qt.rgba(1, 1, 1, 0.2)
                border.width: 1.5
            }

            Image {
                id: userImg
                anchors.fill: parent
                anchors.margins: 2
                source: Qt.resolvedUrl("../data/avatar.png")
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: false
            }

            Rectangle {
                id: userMask
                anchors.fill: userImg
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: userImg
                source: userImg
                maskSource: userMask
            }

            MouseArea {
                id: userMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.userClicked()
            }
        }

        // Password Input Pill
        Rectangle {
            id: pillBg
            width: 330
            height: 46
            radius: 23
            color: Qt.rgba(0.08, 0.09, 0.11, 0.82)
            border.color: root.hasFailed ? "#f85149" : (root.isAuthenticating ? "#58a6ff" : "#3fb950")
            border.width: 1.5

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                spacing: 10

                // Lock icon (Neon green)
                Image {
                    source: Qt.resolvedUrl("../icons/lock.svg")
                    width: 18
                    height: 18
                    sourceSize: Qt.size(18, 18)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Input field
                TextField {
                    id: passwordField
                    width: parent.width - 18 - 32 - 26
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    placeholderText: "Contraseña..."
                    placeholderTextColor: "#8b949e"
                    color: "#ffffff"
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    renderType: Text.NativeRendering
                    font.family: "Inter, Cantarell, Roboto, sans-serif"
                    font.pixelSize: 13
                    focus: true
                    background: null
                    selectByMouse: true

                    onAccepted: root.submitLogin()
                }

                // Submit arrow button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: submitArea.containsMouse ? Qt.rgba(0.25, 0.73, 0.31, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: submitArea.containsMouse ? "#3fb950" : "transparent"
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl("../icons/arrow_forward.svg")
                        width: 15
                        height: 15
                        sourceSize: Qt.size(15, 15)
                    }

                    MouseArea {
                        id: submitArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitLogin()
                    }
                }
            }
        }
    }
}
