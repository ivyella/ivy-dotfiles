pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string activeAppId: ""
    property string activeWindow: ""
    readonly property var appNames: ({
            "kitty": "Terminal",
            "librewolf": "LibreWolf",
            "firefox": "Firefox",
            "dev.zed.zed": "Zed",
            "org.gnome.nautilus": "Files",
            "spotify": "Spotify",
            "steam": "Steam",
            "vesktop": "Discord",
            "codium": "VSCodium"
        })
    property var iconMap: ({})

    function iconFor(appId) {
        const key = normalize(appId);
        const icon = iconMap[key];

        if (icon && icon.length > 0) {
            if (icon.startsWith("/") || icon.startsWith("~/"))
                return icon;
            const resolved = Quickshell.iconPath(icon, true);
            if (resolved && resolved.length > 0)
                return resolved;
        }

        const byId = Quickshell.iconPath(key, true);
        if (byId && byId.length > 0)
            return byId;

        return Quickshell.iconPath(key, false) || "image://icon/" + key;
    }

    function normalize(id) {
        return (id || "").toLowerCase().replace(/\.desktop$/, "").replace(/^.*\//, "").trim();
    }

    Process {
        id: eventStream

        command: ["niri", "msg", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line)
                    return;

                if (line.startsWith("Window focus changed:")) {
                    const match = line.match(/Some\((\d+)\)/);
                    if (!match) {
                        focusedWindowProc.running = false;
                        root.activeAppId = "";
                        root.activeWindow = "";
                        return;
                    }

                    focusedWindowProc.running = true;
                    return;
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 2000
        repeat: false

        onTriggered: eventStream.running = true
    }

    Process {
        id: focusedWindowProc

        command: ["sh", "-c", "niri msg focused-window | grep 'App ID:' | awk -F '\"' '{print $2}'"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim())
                    return;

                const id = normalize(data);
                root.activeAppId = id;
                root.activeWindow = root.appNames[id] ?? id;
                focusedWindowProc.running = false;

                if (!root.iconMap[id] && !iconScanner.running)
                    iconScanner.running = true;
            }
        }
    }

    Process {
        id: iconScanner

        command: ["bash", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null" + " | while read f; do" + " id=$(basename \"$f\" .desktop);" + " icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-);" + " [ -n \"$icon\" ] && echo \"$id|$icon\";" + " done"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length !== 2)
                    return;
                const key = normalize(parts[0]);
                const value = parts[1].trim();
                if (root.iconMap[key])
                    return;
                const copy = Object.assign({}, root.iconMap);
                copy[key] = value;
                root.iconMap = copy;
            }
        }

        Component.onCompleted: running = true
    }
}
