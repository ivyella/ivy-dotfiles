pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Reusables.Theme
import qs.Services
import qs.Services.Notification
import qs.Surfaces.Bar.Modules

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: root

        required property var modelData

        color: Theme.color.bg0
        implicitHeight: Theme.height.bar
        screen: modelData

        anchors {
            bottom: false
            left: true
            right: true
            top: true
        }

        // Left / Right
        RowLayout {
            id: edgeLayout

            anchors.bottomMargin: 0
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 0

            // Left
            RowLayout {
                id: leftSection

                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spacing.xs

                Clock {}

                Window {
                    visible: WindowService.activeAppId !== ""
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Right
            RowLayout {
                id: rightSection

                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spacing.xs

                Network {}

                Volume {}

                Battery {}

                Rectangle {
                    border.color: Theme.color.bg3
                    border.width: 1
                    color: Theme.color.bg2
                    height: Theme.height.sm
                    implicitWidth: groupRow.implicitWidth + Theme.padding.md * 0
                    radius: 0

                    RowLayout {
                        id: groupRow

                        anchors.centerIn: parent
                        spacing: 0

                        Tray {}

                        Notification {}
                    }
                }
            }
        }

        // Center
        Item {
            anchors.centerIn: parent
            height: parent.height
            width: mediaCapsule.implicitWidth
            
            Media {
                id: mediaCapsule

                anchors.centerIn: parent
            }
        }
    }
}
