import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services.Time

BarCapsule {
    Rectangle {
        color: Theme.color.bg3
        height: Theme.height.sm
        implicitWidth: timeText.implicitWidth + Theme.padding.sm * 2
        radius: 0

        Text {
            id: timeText

            anchors.centerIn: parent
            color: Theme.color.fg0
            font.family: Theme.font.ui
            font.pixelSize: Theme.font.sm
            font.weight: Theme.font.normal
            text: Clock.currentTime
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.fg1
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.normal
        text: Clock.currentDate
    }
}
