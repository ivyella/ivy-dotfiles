pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Overlays.NotificationCard
import qs.Reusables.Theme
import qs.Services.Notification

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        id: root

        required property var modelData

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: notifList.contentHeight + 20
        implicitWidth: 360
        layer: WlrLayer.Overlay
        namespace: "ivyshell-notif"
        screen: modelData
        visible: !NotiServer.dnd

        mask: Region {
            item: notifList
        }

        anchors {
            bottom: true
            right: true
            top: true
        }

        margins {
            left: 10
            right: 10
            top: 40
        }

        ListView {
            id: notifList

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: contentHeight
            model: NotiServer.trackedNotifications
            spacing: 5

            add: Transition {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutExpo
                    from: notifList.width
                    property: "x"
                    to: 0
                }
            }
            delegate: NotificationCard {}
            move: Transition {
                NumberAnimation {
                    duration: 300
                    properties: "y"
                }
            }
            remove: Transition {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutExpo
                    from: 0
                    property: "x"
                    to: notifList.width
                }
            }
        }
    }
}
