import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string currentPackage: ""
    property string mergeTime: ""
    property string eta: ""
    property bool building: false

    Process {
        id: genlop
        command: ["genlop", "-c"]
        running: pollTimer.triggered
        stdout: SplitParser {
            onRead: function(line) {
                if (line.includes("Currently merging")) {
                    root.building = true
                }
                if (line.includes("*")) {
                    root.currentPackage = line.trim().replace("* ", "")
                }
                if (line.includes("current merge time")) {
                    root.mergeTime = line.split(":").slice(1).join(":").trim()
                }
                if (line.includes("ETA")) {
                    root.eta = line.split(":").slice(1).join(":").trim()
                }
            }
        }
        onExited: function(code) {
            if (code !== 0) root.building = false
        } 
    }
 
    Timer {
        id: pollTimer
        interval: 30000
        repeat: true
        running: true
    }

    Text {
        visible: root.building
        text: root.currentPackage + " | " + root.mergeTime + " | ETA: " + root.eta
        color: "#d4a843"
    }
}