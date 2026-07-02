import QtQuick
import qs.Overlays.QuickPanel
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services.Notification

BarIconBox {
    id: root

    property bool active: QuickPanel.visible

    color: active || hovered ? Theme.color.accent0 : Theme.color.bg3

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
    icon: BarIcon {
        color: root.hovered || active ? Theme.color.bg3 : Theme.color.accent0
        text: NotiServer.dnd ? "notifications_off" : NotiServer.history.length > 0 ? "notifications_unread" : "notifications"
    }

    onClicked: QuickPanel.toggle()
}
