pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

NotificationServer {
    id: notiDaemon

    property bool dnd: false
    property var history: []

    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true

    onDndChanged: {
        if (!dnd) {
            for (const n of trackedNotifications.values) {
                n.expire();
            }
        }
    }
    onNotification: notification => {
        const name = (notification.appName || "").toLowerCase();

        // 🚫 Fully ignore Spotify notifications
        if (name === "spotify") {
            return;
        }

        // Only now allow tracking
        notification.tracked = true;

        history.unshift({
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            timestamp: new Date().toISOString()
        });

        if (history.length > 100)
            history.pop();

        historyChanged();
    }
}
