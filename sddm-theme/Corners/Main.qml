import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12
import "components"

Item {
    id: root

    height: Screen.height
    width: Screen.width

    // Fullscreen Wallpaper (Messi) with Blur
    Image {
        id: bgSource
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: config.Background ? config.Background : "backgrounds/messi.jpg"
        sourceSize: Qt.size(parent.width, parent.height)
        asynchronous: false
        cache: true
        visible: false
    }

    FastBlur {
        id: backgroundBlur
        anchors.fill: parent
        source: bgSource
        radius: (config.BlurRadius !== undefined && config.BlurRadius !== "") ? parseInt(config.BlurRadius) : 40
    }

    // Subtle dark tint for glassmorphic contrast
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, (config.DimOpacity !== undefined && config.DimOpacity !== "") ? parseFloat(config.DimOpacity) : 0.15)
    }

    // Top-Right: Status Info
    StatusBar {
        id: statusBar
        anchors {
            top: parent.top
            right: parent.right
            margins: 35
        }
    }

    // Top-Center: Big Two-Tone Clock
    BigClock {
        id: bigClock
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(40, parent.height * 0.08)
        }
    }

    // Center: Authentication Pill (User + Password/Face Unlock)
    AuthPill {
        id: authPill
        currentSession: sessionSelector.sessionIndex
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: bigClock.bottom
            topMargin: Math.max(30, parent.height * 0.06)
        }
    }

    // Bottom-Center: GitHub Stats (over Messi's 10)
    GithubStatsCard {
        id: githubStatsCard
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 35
        }
    }

    // Bottom-Left: Power Menu (Soft mint squircle matching lockscreen)
    PowerMenu {
        id: powerMenu
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 35
        }
    }

    // Bottom-Right: Session Selector (Refined glassmorphic pill)
    SessionSelector {
        id: sessionSelector
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 35
        }
    }
}
