pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property int temp: 4000  // kelvin

    function disable() {
        killProc.running = true;
        root.enabled = false;
    }

    function enable() {
        startProc.running = true;
        root.enabled = true;
    }

    function toggle() {
        if (root.enabled) {
            disable();
        } else {
            enable();
        }
    }

    Process {
        id: startProc

        command: ["wlsunset", "-t", root.temp.toString(), "-T", (root.temp + 1).toString()]
        running: false
    }

    Process {
        id: killProc

        command: ["pkill", "-x", "wlsunset"]
        running: false

        onExited: root.enabled = false
    }

    Process {
        command: ["pgrep", "-x", "wlsunset"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") {
                    root.enabled = true;
                } else {
                    console.log("wlsunset is not running at startup.");
                }
            }
        }

        Component.onCompleted: running = true
    }
}
