import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string flagFile: Paths.strip(Paths.home) + "/.config/howdy-sudo-disabled"
    property bool isEnabled: true

    ccWidgetIcon: isEnabled ? "face" : "no_photography"
    ccWidgetPrimaryText: "Facial Sudo"
    ccWidgetSecondaryText: isEnabled ? "Activado" : "Desactivado"
    ccWidgetIsActive: isEnabled
    ccWidgetIsToggle: true

    Process {
        id: checkProc
        command: ["bash", "-c", `[ -f "${root.flagFile}" ] && echo "0" || echo "1"`]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                root.isEnabled = (line.trim() === "1");
            }
        }
    }

    Component.onCompleted: {
        checkProc.running = true;
    }

    onCcWidgetToggled: {
        const nextState = !isEnabled;
        isEnabled = nextState;
        if (nextState) {
            Quickshell.execDetached(["rm", "-f", root.flagFile]);
        } else {
            Quickshell.execDetached(["touch", root.flagFile]);
        }
        if (typeof ToastService !== "undefined" && ToastService) {
            ToastService.showInfo("Facial Sudo", nextState ? "Reconocimiento facial activado para sudo" : "Reconocimiento facial desactivado para sudo");
        }
    }
}
