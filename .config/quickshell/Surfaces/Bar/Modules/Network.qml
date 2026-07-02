import QtQuick
import QtQuick.Layouts
import qs.Reusables.Components
import qs.Reusables.Theme
import qs.Services

Rectangle {
    id: root

    color: Theme.color.bg2
    height: Theme.height.sm
    implicitWidth: contentLayout.implicitWidth + (Network.connectionType !== "ethernet" ? Theme.padding.sm : 0)
    radius: Theme.radius.lg

    RowLayout {
        id: contentLayout

        anchors.leftMargin: Theme.padding.sm
        anchors.rightMargin: Theme.padding.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Network.connectionType !== "ethernet" ? Theme.spacing.sm : 0

        BarIconBox {
            icon: BarIcon {
                Layout.alignment: Qt.AlignVCenter
                text: Network.icon
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Network.connectionType !== "ethernet" ? implicitWidth : 0
            color: Theme.color.fg1
            font.family: Theme.font.ui
            font.pixelSize: Theme.font.sm
            font.weight: Theme.font.normal
            text: Network.label
            visible: Network.connectionType !== "ethernet"
        }
    }
}
