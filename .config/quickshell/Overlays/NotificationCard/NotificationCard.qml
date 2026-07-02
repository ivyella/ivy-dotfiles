import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Reusables.MdIcons
import qs.Reusables.Theme

Rectangle {
    id: notifyItem

    required property var modelData

    border.color: Theme.color.border0
    border.width: 1
    color: dismissArea.containsMouse ? Theme.color.bg2 : Theme.color.bg0
    implicitHeight: fullLayout.implicitHeight + 20
    implicitWidth: ListView.view ? ListView.view.width : 360
    radius: 0

    Timer {
        id: dismissTimer

        interval: 5000
        running: true

        onTriggered: notifyItem.modelData.expire()
    }

    RowLayout {
        id: fullLayout

        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            id: notiIcon

            clip: true
            color: "transparent"
            implicitHeight: 48
            implicitWidth: 48
            radius: 10
            visible: notifyItem.modelData.image !== ""

            IconImage {
                anchors.fill: parent
                asynchronous: true
                implicitSize: 48
                source: notifyItem.modelData.image
                visible: notifyItem.modelData.image !== ""
            }
        }

        ColumnLayout {
            id: textLayout

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: summary

                Layout.fillWidth: true
                color: Theme.color.fg0
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.font.ui
                font.pixelSize: 16
                text: notifyItem.modelData.summary

                onTextChanged: dismissTimer.restart()
            }

            Text {
                Layout.fillWidth: true
                color: Theme.color.fg1
                elide: Text.ElideRight
                font.family: Theme.font.ui
                font.pixelSize: 14
                maximumLineCount: 2
                text: notifyItem.modelData.body
                wrapMode: Text.WordWrap
            }
        }
    }

    MouseArea {
        id: dismissArea

        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: notifyItem.modelData.dismiss()
    }
}
