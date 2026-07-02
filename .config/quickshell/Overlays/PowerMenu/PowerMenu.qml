pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Reusables.MdIcons
import qs.Reusables.Theme

Singleton {
    id: root

    property bool menuVisible: false

    IpcHandler {
        function toggle() {
            root.menuVisible = !root.menuVisible;
        }

        target: "powerMenu"
    }

    PanelWindow {
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.menuVisible

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        MouseArea {
            anchors.fill: parent

            onClicked: root.menuVisible = false
        }

        Rectangle {
            anchors.centerIn: parent
            border.color: Theme.color.border0
            border.width: 2
            color: Theme.color.bg0
            focus: true
            height: buttonRow.implicitHeight + Theme.spacing.xl * 2
            radius: Theme.radius.lg
            width: buttonRow.implicitWidth + Theme.spacing.xl * 2

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    root.menuVisible = false;
            }
            onVisibleChanged: if (visible)
                forceActiveFocus()

            MouseArea {
                anchors.fill: parent

                onClicked: {}
            }

            RowLayout {
                id: buttonRow

                anchors.centerIn: parent
                spacing: Theme.spacing.lg

                Repeater {
                    model: [
                        {
                            icon: "logout",
                            label: "Logout",
                            cmd: "loginctl terminate-user " + Quickshell.env("USER")
                        },
                        {
                            icon: "restart_alt",
                            label: "Reboot",
                            cmd: "reboot"
                        },
                        {
                            icon: "power_settings_new",
                            label: "Shutdown",
                            cmd: "shutdown now"
                        }
                    ]

                    delegate: Rectangle {
                        id: btn

                        property bool hovered: false
                        required property var modelData

                        Layout.preferredHeight: 110
                        Layout.preferredWidth: 110
                        color: hovered ? Theme.color.accent0 : Theme.color.bg2
                        radius: Theme.radius.md

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.spacing.sm

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                color: btn.hovered ? Theme.color.bg0 : Theme.color.fg0
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 42
                                font.variableAxes: ({
                                        "FILL": "1",
                                        "opsz": Theme.icon.lg
                                    })
                                font.weight: 800
                                renderType: Text.NativeRendering
                                text: btn.modelData.icon

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                color: btn.hovered ? Theme.color.bg0 : Theme.color.fg1
                                font.family: Theme.font.ui
                                font.pixelSize: Theme.font.sm
                                font.weight: Theme.font.medium
                                text: btn.modelData.label

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                Quickshell.execDetached(["sh", "-c", btn.modelData.cmd]);
                                root.menuVisible = false;
                            }
                            onEntered: btn.hovered = true
                            onExited: btn.hovered = false
                        }
                    }
                }
            }
        }
    }
}
