pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Reusables.MdIcons
import qs.Reusables.Theme

Item {
    id: root

    property string icon: ""
    readonly property bool isInteracting: trackMouse.pressed || trackMouse.containsMouse
    property string label: ""
    property bool showLabel: true
    property int value: 0

    signal userChanged(int val)

    implicitHeight: sliderCol.implicitHeight

    Column {
        id: sliderCol

        spacing: 8
        width: parent.width

        RowLayout {
            spacing: 8
            visible: showLabel
            width: parent.width

            MdIcons {
                color: root.isInteracting ? Theme.color.accent0 : Theme.color.fg1
                iconSize: 16
                text: root.icon
                visible: root.icon !== ""

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                color: Theme.color.fg1
                font.family: Theme.font.ui
                font.pixelSize: 12
                font.weight: Font.Medium
                text: root.label
            }

            Text {
                color: root.isInteracting ? Theme.color.accent0 : Theme.color.fg2
                font.family: Theme.font.ui
                font.pixelSize: 11
                text: root.value + "%"

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }

        Item {
            id: trackContainer

            height: 32
            width: parent.width

            Rectangle {
                id: sliderTrack

                anchors.centerIn: parent
                color: Theme.color.bg3
                height: 12
                radius: 4
                width: parent.width
            }

            Rectangle {
                id: activeTrack

                anchors.verticalCenter: parent.verticalCenter
                color: Theme.color.accent0
                height: sliderTrack.height
                radius: sliderTrack.radius
                width: {
                    const travel = sliderTrack.width - thumb.width;
                    const ratio = root.value / 100;
                    return (travel * ratio) + (thumb.width / 2);
                }

                Behavior on width {
                    enabled: !trackMouse.pressed

                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }
                }
            }

            Rectangle {
                id: thumb

                anchors.verticalCenter: parent.verticalCenter
                border.color: Theme.color.bg1
                border.width: 3
                color: Theme.color.fg1
                height: 28
                radius: 5
                scale: root.isInteracting ? 1.05 : 1.0
                width: 10
                x: (parent.width - width) * (root.value / 100)

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Behavior on x {
                    enabled: !trackMouse.pressed

                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.color.fg0
                    opacity: trackMouse.pressed ? 0.16 : (trackMouse.containsMouse ? 0.08 : 0)
                    radius: parent.radius

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
            }

            MouseArea {
                id: trackMouse

                function updateValue(mx) {
                    let travel = width - thumb.width;
                    let ratio = Math.max(0, Math.min(1, (mx - thumb.width / 2) / travel));
                    let nextVal = Math.round(ratio * 100);

                    if (nextVal !== root.value) {
                        root.userChanged(nextVal);
                    }
                }

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                preventStealing: true

                onPositionChanged: mouse => {
                    if (pressed)
                        updateValue(mouse.x);
                }
                onPressed: mouse => updateValue(mouse.x)
            }
        }
    }
}
