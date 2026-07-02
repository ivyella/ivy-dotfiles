pragma ComponentBehavior: Bound
import QtQuick
import qs.Reusables.Theme

Rectangle {
    id: root

    readonly property alias hovered: masterMouseArea.containsMouse

    // API
    default property alias icon: iconContent.children

    signal clicked(variant mouse)

    // Styling
    color: Theme.color.bg3
    height: Theme.height.sm
    radius: 0
    width: Theme.height.sm

    Item {
        id: iconContent

        anchors.fill: parent
        anchors.margins: Theme.padding.sm
        enabled: false

        onChildrenChanged: {
            for (let child of children) {
                // geometric centering + visual correction
                child.anchors.horizontalCenter = iconContent.horizontalCenter;
                child.anchors.verticalCenter = iconContent.verticalCenter;

                // subtle correction for font/icon baseline bias
                child.anchors.verticalCenterOffset = -0.5;
            }
        }
    }

    MouseArea {
        id: masterMouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => root.clicked(mouse)
    }
}
