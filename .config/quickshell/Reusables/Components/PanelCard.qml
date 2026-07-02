pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Reusables.Theme

Rectangle {
    id: card

    default property alias contents: bodyCol.children
    property bool headerButton: false
    property string headerButtonLabel: ""
    property string icon: ""
    property bool isExpanded: true
    property string title: ""

    signal headerButtonClicked
    signal headerClicked

    border.color: Theme.color.border0
    border.width: 2
    clip: true
    color: Theme.color.bg1
    implicitHeight: headerRow.height + (isExpanded ? bodyCol.implicitHeight + 20 : 0) + 20
    radius: 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: headerRow

        height: 44
        width: parent.width

        RowLayout {
            spacing: 8

            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
            }

            MdIcons {
                color: Theme.color.accent0
                fill: 1
                iconSize: 16
                text: card.icon
            }

            Text {
                Layout.fillWidth: true
                color: Theme.color.fg0
                font.family: Theme.font.ui
                font.pixelSize: Theme.font.sm
                font.weight: Font.Medium
                text: card.title
            }

            Rectangle {
                color: clearHover.containsMouse ? Theme.color.accent0 : Theme.color.bg2
                height: 22
                radius: 11
                visible: card.headerButton
                width: 52

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: clearHover.containsMouse ? Theme.color.bg0 : Theme.color.fg1
                    font.family: Theme.font.ui
                    font.pixelSize: 10
                    text: card.headerButtonLabel
                }

                MouseArea {
                    id: clearHover

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: mouse => {
                        mouse.accepted = true;
                        card.headerButtonClicked();
                    }
                    onPressed: mouse => mouse.accepted = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            z: -1

            onClicked: mouse => {
                mouse.accepted = true;
                card.headerClicked();
            }
            onPressed: mouse => mouse.accepted = true
        }
    }

    Column {
        id: bodyCol

        opacity: card.isExpanded ? 1 : 0
        spacing: 8

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        anchors {
            bottomMargin: 14
            left: parent.left
            leftMargin: 14
            right: parent.right
            rightMargin: 14
            top: headerRow.bottom
        }
    }
}
