pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false

    function hide() {
        root.visible = false;
    }

    function show() {
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

        target: "command"
    }
}
