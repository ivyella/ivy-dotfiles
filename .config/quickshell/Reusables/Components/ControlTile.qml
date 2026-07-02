pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Reusables.MdIcons
import qs.Reusables.Theme

Rectangle {
    property bool active: false
    property string icon: ""
    property string label: ""

    signal toggled

    border.color: active ? Theme.color.accent0 : Theme.color.border0
    border.width: 0
    color: active ? Qt.rgba(Theme.color.accent0.r, Theme.color.accent0.g, Theme.color.accent0.b, 0.18) : (tileHover.containsMouse ? Theme.color.bg3 : Theme.color.bg2)
    height: 56
    radius: Theme.radius.md

    Behavior on border.color {
        ColorAnimation {
            duration: 140
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Column {
        spacing: 4

        anchors {
            left: parent.left
            margins: 10
            right: parent.right
            top: parent.top
        }

        MdIcons {
            color: active ? Theme.color.accent0 : Theme.color.fg1
            fill: active ? 1 : 0
            iconSize: 16
            text: icon
        }

        Text {
            color: active ? Theme.color.accent0 : Theme.color.fg0
            elide: Text.ElideRight
            font.family: Theme.font.ui
            font.pixelSize: 11
            font.weight: Font.Medium
            text: label
            width: parent.width
        }
    }

    MouseArea {
        id: tileHover

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => {
            mouse.accepted = true;
            toggled();
        }
        onPressed: mouse => mouse.accepted = true
    }
}
