pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.Reusables.MdIcons
import qs.Reusables.Theme

Singleton {
    id: root

    property real anchorX: 0
    property real anchorY: 0
    property var menu: null
    property bool visible: false

    function close() {
        root.visible = false;
        root.menu = null;
    }

    function open(menuHandle, gx, gy) {
        root.menu = menuHandle;
        root.anchorX = gx;
        root.anchorY = gy;
        root.visible = true;
    }

    // ── Menu window ───────────────────────────────────────────────────────────
    PanelWindow {
        id: menuWindow

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.visible && root.menu !== null

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        // dismiss on click outside (accept both left and right clicks)
        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent

            onClicked: root.close()
        }

        QsMenuOpener {
            id: opener

            menu: root.menu
        }

        Rectangle {
            id: menuPanel

            border.color: Theme.color.border0
            border.width: 1
            color: Theme.color.bg2
            implicitHeight: menuCol.implicitHeight + Theme.spacing.sm * 2
            radius: Theme.radius.md
            width: 200
            x: Math.max(Theme.spacing.sm, Math.min(root.anchorX - width / 2, menuWindow.width - width - Theme.spacing.sm))
            y: root.anchorY
            z: 10

            // eat clicks so they don't fall through to the dismiss MouseArea
            MouseArea {
                anchors.fill: parent

                onClicked: {}
            }

            Column {
                id: menuCol

                spacing: 2

                anchors {
                    left: parent.left
                    margins: Theme.spacing.sm
                    right: parent.right
                    top: parent.top
                }

                Repeater {
                    model: opener.children

                    delegate: Loader {
                        property var itemData: modelData
                        required property var modelData

                        sourceComponent: modelData.isSeparator ? separatorComp : itemComp
                        width: menuCol.width
                    }
                }
            }
        }

        // ── Separator ─────────────────────────────────────────────────────────
        Component {
            id: separatorComp

            Rectangle {
                color: "transparent"
                height: 9
                width: parent ? parent.width : 0

                Rectangle {
                    anchors.centerIn: parent
                    color: Theme.color.border0
                    height: 1
                    width: parent.width
                }
            }
        }

        // ── Menu item ─────────────────────────────────────────────────────────
        Component {
            id: itemComp

            Rectangle {
                id: menuItem

                readonly property bool hasSubmenu: itemData?.children?.length > 0
                property var itemData: parent ? (parent as Loader).itemData : null

                color: itemMouse.containsMouse ? Theme.color.bg3 : "transparent"
                height: 32
                radius: Theme.radius.sm
                width: parent ? parent.width : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.padding.sm
                    anchors.rightMargin: Theme.padding.sm
                    spacing: Theme.spacing.sm

                    Text {
                        color: Theme.color.accent0
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.sm
                        text: itemData?.checkState === 2 ? "󰄵" : itemData?.checkState === 1 ? "󰍕" : ""
                        visible: itemData?.checkState !== undefined && itemData?.checkState !== null
                        width: 14
                    }

                    Text {
                        Layout.fillWidth: true
                        color: itemData?.enabled === false ? Theme.color.fg2 : Theme.color.fg0
                        elide: Text.ElideRight
                        font.family: Theme.font.ui
                        font.pixelSize: Theme.font.sm
                        text: itemData?.text ?? ""
                    }

                    Text {
                        color: Theme.color.fg2
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.sm
                        text: ""
                        visible: menuItem.hasSubmenu
                    }
                }

                MouseArea {
                    id: itemMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: menuItem.itemData?.enabled !== false
                    hoverEnabled: true

                    onClicked: {
                        if (!menuItem.hasSubmenu) {
                            menuItem.itemData?.triggered();
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
