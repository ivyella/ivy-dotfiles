import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services

BarCapsule {
    BarIconBox {
        icon: BarIcon {
            Layout.alignment: Qt.AlignVCenter
            text: Audio.muted || Audio.volume === 0 ? "volume_off" : Audio.volume < 50 ? "volume_down" : "volume_up"
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.fg1
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.normal
        text: Audio.volume
    }

    mouseArea {
        enabled: true

        onWheel: wheel => Audio.adjustVolume(wheel.angleDelta.y > 0 ? 5 : -5)
    }
}
