import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Overlays.TrayMenu
import qs.Reusables.Components
import qs.Reusables.Theme

Rectangle {
    color: Theme.color.bg2
    height: Theme.height.sm
    implicitWidth: trayRow.implicitWidth + Theme.padding.md
    radius: Theme.radius.lg

    Row {
        id: trayRow

        anchors.left: parent.left
        anchors.leftMargin: Theme.padding.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.sm

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayIcon

                property string iconSource: {
                    const icon = modelData.icon;
                    if (typeof icon === 'string' || icon instanceof String) {
                        if (icon === "")
                            return "";
                        if (icon.includes("?path=")) {
                            const split = icon.split("?path=");
                            if (split.length !== 2)
                                return icon;
                            const name = split[0];
                            const path = split[1];
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return `file://${path}/${fileName}`;
                        }
                        if (icon.startsWith("/") && !icon.startsWith("file://"))
                            return `file://${icon}`;
                        return icon;
                    }
                    return "";
                }
                required property var modelData

                height: Theme.icon.md
                width: Theme.icon.md

                IconImage {
                    id: iconImg

                    anchors.fill: parent
                    asynchronous: true
                    implicitSize: Theme.icon.md
                    smooth: true
                    source: trayIcon.iconSource !== "" ? trayIcon.iconSource : trayIcon.modelData.icon
                    visible: status === Image.Ready || status === Image.Loading
                }

                // fallback: first letter of app id
                Rectangle {
                    anchors.fill: parent
                    color: Theme.color.bg3
                    radius: Theme.radius.xs
                    visible: iconImg.status === Image.Error || iconImg.status === Image.Null

                    Text {
                        anchors.centerIn: parent
                        color: Theme.color.fg1
                        font.family: Theme.font.ui
                        font.pixelSize: Theme.font.xs
                        text: {
                            const id = trayIcon.modelData.id ?? "";
                            return id ? id.charAt(0).toUpperCase() : "?";
                        }
                    }
                }

                MouseArea {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton && trayIcon.modelData.hasMenu) {
                            const global = trayIcon.mapToGlobal(trayIcon.width / 2, trayIcon.height);
                            if (TrayMenu.visible && TrayMenu.menu === trayIcon.modelData.menu) {
                                TrayMenu.close();
                            } else {
                                TrayMenu.open(trayIcon.modelData.menu, global.x, global.y);
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            TrayMenu.close();
                            trayIcon.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
