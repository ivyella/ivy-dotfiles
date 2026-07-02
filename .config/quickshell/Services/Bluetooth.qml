pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property string connectedDevice: ""
    property bool enabled: false

    // ── Get status ────────────────────────────────────────────────────────────
    function refresh() {
        if (!root.available)
            return;
        statusProc.running = false;
        statusProc.running = true;
    }

    // ── Toggle ────────────────────────────────────────────────────────────────
    function toggle() {
        if (!root.available)
            return;
        const next = !root.enabled;
        Quickshell.execDetached(["bluetoothctl", "power", next ? "on" : "off"]);
        root.enabled = next;
        if (!next)
            root.connectedDevice = "";
    }

    // ── Check if bluetooth hardware exists ────────────────────────────────────
    Process {
        id: checkProc

        command: ["rfkill", "list", "bluetooth"]

        stdout: StdioCollector {
            onStreamFinished: () => {
                root.available = this.text.trim() !== "";
                if (root.available)
                    statusProc.running = true;
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: statusProc

        property bool _powered: false

        command: ["bluetoothctl", "show"]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Powered: yes"))
                    statusProc._powered = true;
            }
        }

        onExited: code => {
            if (code !== 0)
                console.warn("Bluetooth: bluetoothctl show exited", code);
        }
        onRunningChanged: {
            if (running) {
                _powered = false;
            } else {
                root.enabled = _powered;
                if (root.enabled)
                    deviceProc.running = true;
            }
        }
    }

    // ── Get connected device ──────────────────────────────────────────────────
    Process {
        id: deviceProc

        property string _name: ""

        command: ["bluetoothctl", "info"]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Name:"))
                    deviceProc._name = data.split("Name:")[1].trim();
            }
        }

        onRunningChanged: {
            if (!running)
                root.connectedDevice = _name;
        }
    }

    // ── Poll ──────────────────────────────────────────────────────────────────
    Timer {
        interval: 10000
        repeat: true
        running: root.available

        onTriggered: root.refresh()
    }
}
