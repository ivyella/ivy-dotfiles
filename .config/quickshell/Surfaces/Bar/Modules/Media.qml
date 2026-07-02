import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services

BarCapsule {
    visible: Media.hasPlayer

    BarIconBox {
        visible: Media.isSpotify

        icon: BarIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "music_note"
        }
    }

    BarIconBox {
        visible: Media.isFirefox

        icon: BarIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "language"
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.fg0
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.normal
        text: Media.title
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.accent0
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        text: "•"
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.fg1
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.light
        text: Media.artist
    }

    mouseArea {
        acceptedButtons: Qt.LeftButton
        enabled: true

        onClicked: Media.togglePlaying()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Media.next();
            else
                Media.previous();
        }
    }
}
