pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var apps: []
    property var filteredApps: {
        const q = query.trim().toLowerCase();
        let list = q === "" ? apps.slice() : apps.filter(a => a.name.toLowerCase().includes(q));

        list.sort((a, b) => {
            const aPinned = root.pinnedApps.indexOf(a.name);
            const bPinned = root.pinnedApps.indexOf(b.name);
            const aIsPinned = aPinned !== -1;
            const bIsPinned = bPinned !== -1;

            if (aIsPinned && bIsPinned)
                return aPinned - bPinned;
            if (aIsPinned)
                return -1;
            if (bIsPinned)
                return 1;

            const aCount = root.launchCounts[a.name] || 0;
            const bCount = root.launchCounts[b.name] || 0;
            if (bCount !== aCount)
                return bCount - aCount;

            return a.name.localeCompare(b.name);
        });

        return list;
    }
    property var launchCounts: ({})
    property var pinnedApps: []
    property string query: ""
    property bool scanning: false
    property bool visible: false

    function hide() {
        root.visible = false;
        root.query = "";
    }

    function iconFor(app) {
        if (!app)
            return Quickshell.iconPath("application-x-executable", false);
        if (!app.icon || app.icon === "")
            return Quickshell.iconPath("application-x-executable", false);

        if (app.icon.startsWith("/") || app.icon.startsWith("~/"))
            return app.icon;
        const resolved = Quickshell.iconPath(app.icon, true);
        if (resolved && resolved.length > 0)
            return resolved;
        return Quickshell.iconPath(app.icon, false) || "image://icon/" + app.icon;
    }

    function launch(app) {
        const counts = Object.assign({}, root.launchCounts);
        counts[app.name] = (counts[app.name] || 0) + 1;
        root.launchCounts = counts;
        root.save();

        launchProc.command = ["bash", "-c", "nohup " + app.exec + " >/dev/null 2>&1 &disown"];
        launchProc.running = true;
        root.hide();
    }

    function rescan() {
        root.apps = [];
        root.scanning = true;
        scanner.running = true;
    }

    function save() {
        adapter.counts = root.launchCounts;
        adapter.pinned = root.pinnedApps;
        dataFile.writeAdapter();
    }

    function show() {
        root.query = "";
        root.visible = true;
    }

    function toggle() {
        if (root.visible)
            root.hide();
        else
            root.show();
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        target: "launcher"
    }

    FileView {
        id: dataFile

        blockLoading: true
        path: Quickshell.env("HOME").toString() + "/.config/ivyshell/launcher_data.json"

        Component.onCompleted: reload()
        onLoadFailed: {
            root.launchCounts = {};
            root.pinnedApps = [];
            root.save();
            root.rescan();
        }
        onLoaded: {
            root.launchCounts = adapter.counts || {};
            root.pinnedApps = adapter.pinned || [];
            root.rescan();
        }

        JsonAdapter {
            id: adapter

            property var counts
            property var pinned
        }
    }

    Process {
        id: scanner

        command: ["bash", "-c", "find /usr/share/applications ~/.local/share/applications" + " /var/lib/flatpak/exports/share/applications" + " ~/.local/share/flatpak/exports/share/applications" + " -name '*.desktop' 2>/dev/null" + " | while read f; do" + " name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-);" + " exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ *%[^ ]*//g;s/^ *//;s/ *$//');" + " icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-);" + " nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2-);" + " [ -n \"$name\" ] && [ -n \"$exec\" ] && [ \"$nodisplay\" != 'true' ]" + " && echo \"$name|$exec|$icon\";" + " done"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length < 2)
                    return;
                const name = parts[0].trim();
                if (root.apps.some(a => a.name === name))
                    return;
                root.apps = [...root.apps,
                    {
                        name: name,
                        exec: parts[1].trim(),
                        icon: parts.length >= 3 ? parts[2].trim() : ""
                    }
                ];
            }
        }

        onRunningChanged: {
            if (!running)
                root.scanning = false;
        }
    }

    Process {
        id: launchProc

        command: ["bash", "-c", ""]
    }
}
