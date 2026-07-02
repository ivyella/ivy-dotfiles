pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Reusables.Components
import qs.Reusables.MdIcons
import qs.Reusables.Theme
import qs.Services
import qs.Services.Notification

Singleton {
    id: root

    // ── interaction debounce (brightness/wifi/bt only) ────────────────────────
    property bool _userInteracting: false
    property bool notificationsExpanded: true

    // ── accordion state ───────────────────────────────────────────────────────
    property bool settingsExpanded: true

    // ── visibility ────────────────────────────────────────────────────────────
    property bool visible: false

    function _markInteracting() {
        root._userInteracting = true;
        interactDebounce.restart();
    }

    // ── polling ───────────────────────────────────────────────────────────────
    function poll() {
        if (!root.visible || root._userInteracting)
            return;
        brightGetProc.running = true;
        btStatusProc.running = true;
    }

    function toggle() {
        root.visible = !root.visible;
    }

    onVisibleChanged: if (visible)
        poll()

    Timer {
        id: interactDebounce

        interval: 2000
        repeat: false

        onTriggered: root._userInteracting = false
    }

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
                duration: 100
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
                    radius: Theme.radius.sm
                    visible: card.headerButton
                    width: 52

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: clearHover.containsMouse ? Theme.color.bg1 : Theme.color.fg1
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

                MdIcons {
                    color: Theme.color.fg2
                    iconSize: 16
                    text: card.isExpanded ? "expand_less" : "expand_more"
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

    IpcHandler {
        function toggle(): void {
            root.visible = !root.visible;
        }

        target: "quickpanel"
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible

        onTriggered: root.poll()
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  WINDOW
    // ══════════════════════════════════════════════════════════════════════════
    PanelWindow {
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.visible

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        // BackgroundEffect.blurRegion: Region { item: root.contentItem }
        MouseArea {
            anchors.fill: parent
            z: -1

            onClicked: root.visible = false
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 40
            spacing: 8
            width: 340

            PanelCard {
                icon: "tune"
                isExpanded: root.settingsExpanded
                title: "Quick Settings"

                GridLayout {
                    columnSpacing: 7
                    columns: 2
                    rowSpacing: 7
                    width: parent.width

                    ControlTile {
                        Layout.fillWidth: true
                        active: Network.enabled
                        icon: Network.icon
                        label: Network.label

                        onToggled: Network.toggle()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        active: Bluetooth.enabled
                        icon: "bluetooth"
                        label: Bluetooth.connectedDevice !== "" ? Bluetooth.connectedDevice : "Bluetooth"
                        visible: Bluetooth.available

                        onToggled: Bluetooth.toggle()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        active: NightLight.enabled
                        icon: root.nightLightEnabled ? "bedtime" : "bedtime_off"
                        label: "Night Light"

                        onToggled: NightLight.toggle()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        active: NotiServer.dnd
                        icon: NotiServer.dnd ? "notifications_off" : "notifications"
                        label: "Do Not Disturb"

                        onToggled: NotiServer.dnd = !NotiServer.dnd
                    }
                }

                ControlSlider {
                    icon: Audio.muted || Audio.volume === 0 ? "volume_off" : "volume_up"
                    label: "Volume"
                    value: Audio.volume
                    width: parent.width

                    onUserChanged: val => Audio.setVolume(val)
                }

                ControlSlider {
                    icon: "brightness_5"
                    label: "Brightness"
                    value: Brightness.level
                    visible: Brightness.available
                    width: parent.width

                    onUserChanged: val => Brightness.setLevel(val)
                }
            }

            // ── Notifications card ────────────────────────────────────────────
            PanelCard {
                headerButton: NotiServer.history.length > 0
                headerButtonLabel: "clear"
                icon: NotiServer.history.length > 0 ? "notifications_unread" : "notifications"
                isExpanded: root.notificationsExpanded
                title: "Notifications"

                onHeaderButtonClicked: NotiServer.history = []
                onHeaderClicked: root.notificationsExpanded = !root.notificationsExpanded

                Item {
                    clip: true
                    height: notifList.count > 0 ? Math.min(notifList.contentHeight, 400) : emptyLabel.implicitHeight + 24
                    width: parent.width

                    ListView {
                        id: notifList

                        anchors.fill: parent
                        clip: true
                        model: NotiServer.history
                        spacing: 6

                        add: Transition {
                            NumberAnimation {
                                duration: 180
                                from: 0
                                property: "opacity"
                                to: 1
                            }
                        }
                        delegate: NotificationDelegate {}
                        remove: Transition {
                            NumberAnimation {
                                duration: 140
                                from: 1
                                property: "opacity"
                                to: 0
                            }
                        }
                    }

                    Text {
                        id: emptyLabel

                        anchors.centerIn: parent
                        color: Theme.color.fg2
                        font.family: Theme.font.ui
                        font.pixelSize: Theme.font.sm
                        text: "No notifications"
                        visible: notifList.count === 0
                    }
                }
            }
        }
    }

    component NotificationDelegate: Rectangle {
        required property var modelData

        border.color: Theme.color.border0
        border.width: 0
        color: Theme.color.bg2
        height: notifInner.implicitHeight + 18
        radius: 10
        width: ListView.view.width

        Column {
            id: notifInner

            spacing: 3

            anchors {
                fill: parent
                margins: 10
            }

            RowLayout {
                width: parent.width

                Text {
                    Layout.fillWidth: true
                    color: Theme.color.fg2
                    elide: Text.ElideRight
                    font.family: Theme.font.ui
                    font.pixelSize: 10
                    text: modelData.appName ?? ""
                }

                Text {
                    color: Theme.color.fg2
                    font.family: Theme.font.ui
                    font.pixelSize: 10
                    text: modelData.timestamp ? Qt.formatDateTime(new Date(Date.parse(modelData.timestamp)), "hh:mm AP") : ""
                }
            }

            Text {
                color: Theme.color.fg0
                font.family: Theme.font.ui
                font.pixelSize: 13
                font.weight: Font.Medium
                text: modelData.summary ?? ""
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Text {
                color: Theme.color.fg1
                elide: Text.ElideRight
                font.family: Theme.font.ui
                font.pixelSize: 11
                maximumLineCount: 3
                text: modelData.body ?? ""
                visible: (modelData.body ?? "") !== ""
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  COMPONENTS
    // ══════════════════════════════════════════════════════════════════════════

    component PanelCard: Rectangle {
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
        border.width: 1
        clip: true
        color: Theme.color.bg1
        implicitHeight: headerRow.height + (isExpanded ? bodyCol.implicitHeight + 20 : 0) + 20
        radius: o
        width: parent.width

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

                MdIcons {
                    color: Theme.color.fg2
                    iconSize: 16
                    text: card.isExpanded ? "expand_less" : "expand_more"
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
    component SectionLabel: Text {
        color: Theme.color.fg2
        font.family: Theme.font.ui
        font.letterSpacing: 0.8
        font.pixelSize: 9
        font.weight: Font.Medium
        topPadding: 4
    }
}
