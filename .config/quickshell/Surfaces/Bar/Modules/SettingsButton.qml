import QtQuick
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Surfaces.Settings

BarIconBox {
    id: root

    property bool active: Settings.visible

    // Use the 'hovered' alias from the base component
    color: active || hovered ? Theme.color.accent0 : Theme.color.bg3

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
    icon: BarIcon {
        color: root.hovered || active ? Theme.color.bg3 : Theme.color.accent0
        text: "settings"
    }

    // Connect to the signal defined in BarIconBox
    onClicked: Settings.visible = !Settings.visible
}
