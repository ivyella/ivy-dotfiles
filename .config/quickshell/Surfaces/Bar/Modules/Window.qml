import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services

BarCapsule {
    BarIconBox {
        visible: WindowService.activeAppId !== ""

        icon: Item {
            anchors.centerIn: parent
            height: Theme.icon.md
            width: Theme.icon.md

            Image {
                id: iconImg

                anchors.centerIn: parent
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                height: Theme.icon.md
                smooth: true
                source: WindowService.iconFor(WindowService.activeAppId)
                sourceSize: Qt.size(Theme.icon.md * 2, Theme.icon.md * 2)
                visible: status === Image.Ready
                width: Theme.icon.md
            }

            Text {
                anchors.centerIn: parent
                color: Theme.color.accent0
                font.family: Theme.font.ui
                font.pixelSize: Theme.font.sm
                text: WindowService.activeAppId ? WindowService.activeAppId.charAt(0).toUpperCase() : "?"
                visible: iconImg.status !== Image.Ready
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        color: Theme.color.fg0
        elide: Text.ElideRight
        font.family: Theme.font.ui
        font.pixelSize: Theme.font.sm
        font.weight: Theme.font.normal
        maximumLineCount: 1
        text: WindowService.activeWindow
    }
}
