pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string connectionType: ""
    property bool enabled: false
    readonly property string icon: connectionType === "ethernet" ? "router" : connectionType === "wifi" ? "wifi" : "wifi_off"
    readonly property string label: connectionType === "ethernet" ? "Ethernet" : connectionType === "wifi" ? ssid : "Disconnected"
    property string ssid: "Disconnected"

    function refresh() {
        typeProc.running = false;
        typeProc.running = true;
    }

    function toggle() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.enabled ? "off" : "on"]);
        Qt.callLater(refresh);
    }

    Component.onCompleted: {
        refresh();
        ssidProc.running = true;
    }

    Process {
        id: typeProc

        command: ["nmcli", "-t", "-f", "TYPE", "con", "show", "--active"]

        stdout: StdioCollector {
            onStreamFinished: () => {
                const types = this.text.split("\n");
                const first = types[0] ?? "";
                if (first.includes("ethernet"))
                    root.connectionType = "ethernet";
                else if (first.includes("wireless"))
                    root.connectionType = "wifi";
                else
                    root.connectionType = "";
                root.enabled = root.connectionType !== "";
            }
        }
    }

    Process {
        id: ssidProc

        property string _matched: ""

        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("yes:"))
                    ssidProc._matched = data.split(":")[1] ?? "";
            }
        }

        onRunningChanged: {
            if (running) {
                _matched = "";
            } else {
                root.ssid = _matched !== "" ? _matched : "Disconnected";
                _matched = "";
            }
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: () => {
                root.refresh();
                if (root.connectionType === "wifi")
                    ssidProc.running = true;
            }
        }
    }
}
