pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Reusables.Theme

Rectangle {
    id: root

    default property alias content: contentLayout.children
    property alias mouseArea: mouseAreaImpl

    border.color: Theme.color.bg3
    border.width: 1

    color: Theme.color.bg2
    height: Theme.height.sm

    implicitWidth: contentLayout.implicitWidth + Theme.padding.sm
    radius: 0

    RowLayout {
        id: contentLayout

        anchors.leftMargin: Theme.padding.sm
        anchors.rightMargin: Theme.padding.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.sm
    }

    MouseArea {
        id: mouseAreaImpl

        anchors.fill: parent
        enabled: false
    }
}
