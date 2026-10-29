import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    width: 490
    height: 175
    radius: 18
    color: Qt.rgba(0.08, 0.09, 0.11, 0.75)
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    property string userName: "Edgar Briceño"
    property string userLogin: "EDGAR-BRI"
    property int reposCount: 54
    property int followersCount: 7
    property int contributionsCount: 1871
    property var weeksData: []

    function loadStats() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../data/github_stats.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data.name) root.userName = data.name
                        if (data.login) root.userLogin = data.login
                        if (data.repos !== undefined) root.reposCount = data.repos
                        if (data.followers !== undefined) root.followersCount = data.followers
                        if (data.contributions !== undefined) root.contributionsCount = data.contributions
                        if (data.weeks) root.weeksData = data.weeks
                    } catch (e) {
                        console.warn("SDDM GithubStats error:", e)
                    }
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: loadStats()

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.loadStats()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 9

        // Header: Avatar + Name + Terminal Icon
        Row {
            width: parent.width
            height: 38
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(1, 1, 1, 0.1)
                clip: true

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../data/avatar.png")
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 38 - 10 - 28
                spacing: 1

                Text {
                    text: root.userName
                    color: "#f0f6fc"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    text: "@" + root.userLogin
                    color: "#8b949e"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }

            Image {
                source: Qt.resolvedUrl("../icons/terminal.svg")
                width: 20
                height: 20
                sourceSize: Qt.size(20, 20)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Stats row (Badges)
        Row {
            width: parent.width
            spacing: 6

            // Contributions pill
            Rectangle {
                height: 22
                width: contribText.implicitWidth + 16
                radius: 11
                color: Qt.rgba(0.25, 0.73, 0.31, 0.15)
                border.color: Qt.rgba(0.25, 0.73, 0.31, 0.35)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: "#3fb950"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: contribText
                        text: root.contributionsCount.toLocaleString() + " contribs"
                        color: "#3fb950"
                        font.pixelSize: 10
                        font.bold: true
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Repos pill
            Rectangle {
                height: 22
                width: repoText.implicitWidth + 14
                radius: 11
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: repoText
                    anchors.centerIn: parent
                    text: root.reposCount + " repos"
                    color: "#c9d1d9"
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
            }

            // Followers pill
            Rectangle {
                height: 22
                width: followText.implicitWidth + 14
                radius: 11
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: followText
                    anchors.centerIn: parent
                    text: root.followersCount + " followers"
                    color: "#c9d1d9"
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
            }
        }

        // Contribution Heatmap Grid
        Item {
            width: parent.width
            height: 66
            clip: true

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: root.weeksData

                    Column {
                        spacing: 3
                        property var daysList: modelData

                        Repeater {
                            model: daysList

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 2
                                color: {
                                    var c = modelData.color
                                    if (!c || c === "#ebedf0" || modelData.count === 0)
                                        return Qt.rgba(1, 1, 1, 0.08)
                                    return c
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
