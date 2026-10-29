import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    property real widgetWidth: 500
    property real widgetHeight: 180
    property real defaultWidth: 500
    property real defaultHeight: 180
    property real minWidth: 260
    property real minHeight: 140
    property string instanceId: ""
    property var instanceData: null
    property bool lockScreen: false
    property var lockHost: null
    property var screen: null
    property var pluginService: null
    property string pluginId: ""

    property string userName: "Edgar Briceño"
    property string userLogin: "EDGAR-BRI"
    property string avatarUrl: "https://avatars.githubusercontent.com/u/177440022?v=4"
    property int reposCount: 54
    property int followersCount: 7
    property int contributionsCount: 1871
    property var weeksData: []

    readonly property string pluginDir: Paths.strip(Paths.config) + "/plugins/githubStats"
    readonly property string statsFilePath: Paths.strip(Paths.state) + "/github_stats.json"

    function parseStats(content) {
        if (!content) return;
        try {
            const data = JSON.parse(content);
            if (data.name) root.userName = data.name;
            if (data.login) root.userLogin = data.login;
            if (data.avatarUrl) root.avatarUrl = data.avatarUrl;
            if (data.repos !== undefined) root.reposCount = data.repos;
            if (data.followers !== undefined) root.followersCount = data.followers;
            if (data.contributions !== undefined) root.contributionsCount = data.contributions;
            if (data.weeks) root.weeksData = data.weeks;
        } catch (e) {
            console.warn("Failed to parse github_stats.json:", e);
        }
    }

    FileView {
        id: statsFile
        path: root.statsFilePath
        watchChanges: true
        onLoaded: root.parseStats(text())
    }

    Process {
        id: fetchProc
        command: ["bash", root.pluginDir + "/fetch.sh"]
        running: false
        onExited: exitCode => {
            if (exitCode === 0) statsFile.reload();
        }
    }

    Timer {
        id: fetchTimer
        interval: 1800000 // 30 min
        running: true
        repeat: true
        onTriggered: if (!fetchProc.running) fetchProc.running = true
    }

    Component.onCompleted: {
        statsFile.reload();
        if (!fetchProc.running) fetchProc.running = true;
    }

    // Glass Card Container
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(0.08, 0.09, 0.11, 0.72)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header: Avatar + Name + GitHub Icon
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
                        source: root.avatarUrl
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
                        width: parent.width
                    }

                    Text {
                        text: "@" + root.userLogin
                        color: "#8b949e"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                DIcon {
                    name: "terminal"
                    size: 20
                    color: "#3fb950"
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
                    width: contribText.implicitWidth + 14
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
                        font.weight: Font.Medium
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
                        font.weight: Font.Medium
                    }
                }
            }

            // Mini Contribution Heatmap
            Item {
                width: parent.width
                height: 70
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
                                        const c = modelData.color;
                                        if (!c || c === "#ebedf0" || modelData.count === 0)
                                            return Qt.rgba(1, 1, 1, 0.08);
                                        return c;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
