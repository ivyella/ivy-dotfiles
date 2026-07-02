pragma Singleton
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool batteryAvailable: false
    property string batteryIcon: {
        if (root.isCharging)
            return "battery_android_bolt";
        const lvl = root.batteryLevel;
        if (lvl >= 95)
            return "battery_android_full";
        if (lvl >= 80)
            return "battery_android_6";
        if (lvl >= 65)
            return "battery_android_5";
        if (lvl >= 50)
            return "battery_android_4";
        if (lvl >= 35)
            return "battery_android_3";
        if (lvl >= 20)
            return "battery_android_2";
        if (lvl >= 10)
            return "battery_android_1";
        return "battery_android_0";
    }
    property int batteryLevel: 100
    property bool isCharging: false
    property bool isLow: batteryLevel <= 20

    Process {
        id: batCheckProc

        command: ["bash", "-c", "test -f /sys/class/power_supply/BAT1/capacity && echo yes || echo no"]

        stdout: SplitParser {
            onRead: data => {
                root.batteryAvailable = data.trim() === "yes";
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: batLevelProc

        command: ["bash", "-c", "cat /sys/class/power_supply/BAT1/capacity"]

        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;
                const val = parseInt(data.trim());
                if (!isNaN(val))
                    root.batteryLevel = val;
            }
        }
    }

    Process {
        id: batStatusProc

        command: ["bash", "-c", "cat /sys/class/power_supply/BAT1/status"]

        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;
                root.isCharging = data.trim() === "Charging";
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!root.batteryAvailable)
                return;
            batLevelProc.running = true;
            batStatusProc.running = true;
        }
    }
}
