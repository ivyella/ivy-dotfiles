import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services.Battery

BarCapsule {
    visible: Battery.batteryAvailable

    BarIconBox {
        icon: BarIcon {
            Layout.alignment: Qt.AlignVCenter
            color: Battery.isLow && !Battery.isCharging ? Theme.color.red0 : Battery.isCharging ? Theme.color.green1 : Theme.color.accent0
            text: Battery.batteryIcon
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Battery.isLow && !Battery.isCharging ? Theme.color.red0 : Theme.color.fg1
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.normal
        text: Battery.batteryLevel
    }
}
