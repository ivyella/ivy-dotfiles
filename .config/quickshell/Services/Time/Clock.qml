pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string currentDate: formatDate()
    property string currentTime: formatTime()

    function formatDate() {
        return Qt.formatDateTime(new Date(), "ddd, MMM dd");
    }

    function formatTime() {
        return Qt.formatDateTime(new Date(), "hh:mm AP");
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            root.currentTime = root.formatTime();
            root.currentDate = root.formatDate();
        }
    }
}
