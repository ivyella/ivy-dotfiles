pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel 2.10
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Reusables.Theme
import qs.Services
import qs.Services.Config

PanelWindow {
    id: root

    // ── tab state ─────────────────────────────────────────────────
    property int currentTab: 0 // 0 = apps, 1 = themes, 2 = wallpapers
    property var filteredFonts: {
        const q = searchInput.text.toLowerCase();

        return Config.fonts.filter(f => q === "" || f.toLowerCase().includes(q));
    }
    readonly property var tabKeys: ["apps", "themes", "wallpapers", "fonts"]
    readonly property var tabPrefixes: ["[1/4] Run:", "[2/4] Themes", "[3/4] Wallpapers", "[4/4] Fonts:"]

    function nextTab() {
        currentTab = (currentTab + 1) % 4;
        searchInput.forceActiveFocus();
    }

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: LauncherService.visible

    onVisibleChanged: {
        if (visible) {
            currentTab = 0;
            focusTimer.start();
        }
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }

    Timer {
        id: focusTimer

        interval: 30
        repeat: false

        onTriggered: searchInput.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent

        onClicked: LauncherService.hide()
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        border.color: Theme.color.bg3
        border.width: 1
        color: Theme.color.bg1
        height: 520
        radius: 0
        width: 480

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                LauncherService.hide();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Tab) {
                root.nextTab();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down) {
                if (root.currentTab === 0)
                    listView.incrementCurrentIndex();
                else if (root.currentTab === 3)
                    fontList.incrementCurrentIndex();

                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Up) {
                if (root.currentTab === 0)
                    listView.decrementCurrentIndex();
                else if (root.currentTab === 3)
                    fontList.decrementCurrentIndex();

                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.currentTab === 0) {
                    const i = listView.currentIndex;
                    if (i >= 0 && i < LauncherService.filteredApps.length)
                        LauncherService.launch(LauncherService.filteredApps[i]);
                } else if (root.currentTab === 3) {
                    const i = fontList.currentIndex;
                    const font = root.filteredFonts[i];

                    if (font) {
                        Config.setFont(font, Config.fontMono, Config.fontScale, Config.fontWeight);
                    }
                }

                event.accepted = true;
                return;
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.lg
            spacing: Theme.spacing.md

            // ── search bar ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                border.color: searchInput.activeFocus ? Theme.color.accent0 : Theme.color.border0
                border.width: 1
                color: Theme.color.bg2
                implicitHeight: 36
                radius: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.padding.md
                    anchors.rightMargin: Theme.padding.md
                    spacing: Theme.spacing.sm

                    // tab prefix indicator
                    Text {
                        id: prefixLabel

                        color: Theme.color.accent0
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.md
                        text: root.tabPrefixes[root.currentTab]
                    }

                    TextInput {
                        id: searchInput

                        Layout.fillWidth: true
                        color: Theme.color.fg0
                        font.family: Theme.font.ui
                        font.pixelSize: Theme.font.md
                        selectedTextColor: Theme.color.bg0
                        selectionColor: Theme.color.accent0
                        text: LauncherService.query
                        visible: root.currentTab === 0 || root.currentTab === 3

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                LauncherService.hide();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && root.currentTab === 0) {
                                listView.incrementCurrentIndex();
                                panel.forceActiveFocus();
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.currentTab === 0) {
                                if (listView.currentIndex >= 0 && listView.currentIndex < LauncherService.filteredApps.length)
                                    LauncherService.launch(LauncherService.filteredApps[listView.currentIndex]);
                                event.accepted = true;
                            }
                        }
                        onTextChanged: {
                            LauncherService.query = text;
                            listView.currentIndex = 0;
                        }
                    }

                    // rescan (apps tab only)
                    Rectangle {
                        color: rescanMouse.containsMouse ? Theme.color.bg3 : "transparent"
                        height: 24
                        radius: 0
                        visible: root.currentTab === 0
                        width: 24

                        Text {
                            anchors.centerIn: parent
                            color: LauncherService.scanning ? Theme.color.accent0 : Theme.color.fg2
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.font.md
                            text: LauncherService.scanning ? "" : "󰑐"

                            RotationAnimator on rotation {
                                duration: 1000
                                from: 0
                                loops: Animation.Infinite
                                running: LauncherService.scanning
                                to: 360
                            }
                        }

                        MouseArea {
                            id: rescanMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: LauncherService.rescan()
                        }
                    }
                }
            }

            // ── pinned row (apps tab only) ────────────────────────
            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacing.sm
                visible: root.currentTab === 0 && LauncherService.pinnedApps.length > 0

                Repeater {
                    model: {
                        void LauncherService.pinnedApps.length;
                        return LauncherService.pinnedApps.map(name => LauncherService.apps.find(a => a.name === name)).filter(a => a !== undefined);
                    }

                    delegate: Item {
                        id: pinnedItem

                        required property var modelData

                        height: pinnedCol.implicitHeight + Theme.spacing.xs * 2
                        width: 56

                        Rectangle {
                            anchors.fill: parent
                            color: pinnedMouse.containsMouse ? Theme.color.bg3 : "transparent"
                            radius: 0
                        }

                        Column {
                            id: pinnedCol

                            anchors.centerIn: parent
                            spacing: 4

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                asynchronous: true
                                height: Theme.icon.lg
                                smooth: true
                                source: LauncherService.iconFor(pinnedItem.modelData)
                                sourceSize: Qt.size(Theme.icon.lg, Theme.icon.lg)
                                width: Theme.icon.lg
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Theme.color.fg1
                                elide: Text.ElideRight
                                font.family: Theme.font.ui
                                font.pixelSize: Theme.font.sm
                                horizontalAlignment: Text.AlignHCenter
                                text: pinnedItem.modelData.name
                                width: pinnedItem.width - Theme.spacing.xs * 2
                            }
                        }

                        MouseArea {
                            id: pinnedMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: LauncherService.launch(pinnedItem.modelData)
                        }
                    }
                }
            }

            // ── apps tab ──────────────────────────────────────────
            ListView {
                id: listView

                Layout.fillHeight: true
                Layout.fillWidth: true
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                currentIndex: 0
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                model: LauncherService.filteredApps
                visible: root.currentTab === 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                delegate: Item {
                    id: appItem

                    required property int index
                    readonly property bool isHovered: rowMouse.containsMouse
                    readonly property bool isSelected: listView.currentIndex === index
                    required property var modelData

                    height: 40
                    width: listView.width

                    Rectangle {
                        anchors.fill: parent
                        color: appItem.isSelected ? Theme.color.bg3 : appItem.isHovered ? Theme.color.bg2 : "transparent"
                        radius: 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.md
                        anchors.rightMargin: Theme.padding.sm
                        spacing: Theme.spacing.md

                        Image {
                            asynchronous: true
                            height: Theme.icon.md
                            smooth: true
                            source: LauncherService.iconFor(appItem.modelData)
                            sourceSize: Qt.size(Theme.icon.md, Theme.icon.md)
                            width: Theme.icon.md
                        }

                        Text {
                            Layout.fillWidth: true
                            color: appItem.isSelected ? Theme.color.fg0 : Theme.color.fg1
                            elide: Text.ElideRight
                            font.family: Theme.font.ui
                            font.pixelSize: Theme.font.md
                            text: appItem.modelData.name
                        }
                    }

                    MouseArea {
                        id: rowMouse

                        acceptedButtons: Qt.LeftButton
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: LauncherService.launch(appItem.modelData)
                        onEntered: listView.currentIndex = appItem.index
                    }
                }
            }

            // ── themes tab ────────────────────────────────────────
            ScrollView {
                id: themeScroll

                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                contentWidth: availableWidth
                visible: root.currentTab === 1

                ColumnLayout {
                    spacing: Theme.spacing.lg
                    width: themeScroll.availableWidth

                    Repeater {
                        delegate: PackRow {
                            required property string fileBaseName
                            required property string filePath

                            Layout.fillWidth: true
                            packBaseName: fileBaseName
                            packPath: filePath
                        }
                        model: FolderListModel {
                            folder: "file://" + Quickshell.env("HOME") + "/.config/ivylink/themes/colors/"
                            nameFilters: ["*.json"]
                            showDirs: false
                            showFiles: true
                        }
                    }
                }
            }

            // ── wallpapers tab ────────────────────────────────────
            GridView {
                id: wallGrid

                Layout.fillHeight: true
                Layout.fillWidth: true
                boundsBehavior: Flickable.StopAtBounds
                cellHeight: 95
                cellWidth: 148
                clip: true
                flickDeceleration: 3000
                leftMargin: (width % cellWidth) / 2
                maximumFlickVelocity: 8000
                visible: root.currentTab === 2

                delegate: Item {
                    id: wallDelegate

                    required property string filePath

                    height: wallGrid.cellHeight
                    width: wallGrid.cellWidth

                    Rectangle {
                        anchors.centerIn: parent
                        clip: true
                        color: Theme.color.bg2
                        height: 85
                        radius: 0
                        width: 135

                        Image {
                            anchors.fill: parent
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            source: wallDelegate.filePath
                            sourceSize.height: 85
                            sourceSize.width: 135
                        }

                        Rectangle {
                            anchors.fill: parent
                            border.color: Config.currentWallpaper === wallDelegate.filePath ? Theme.color.accent0 : "transparent"
                            border.width: 2
                            color: "transparent"
                            radius: 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: Config.setWallpaper(wallDelegate.filePath)
                            }
                        }
                    }
                }
                model: FolderListModel {
                    folder: "file://" + Quickshell.env("HOME") + "/ivyos/ivyshell/themes/wallpapers/"
                    nameFilters: ["*.png", "*.jpg", "*.jpeg"]
                }
            }

            ListView {
                id: fontList

                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                currentIndex: 0
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                model: root.filteredFonts
                visible: root.currentTab === 3

                delegate: Item {
                    required property int index
                    required property string modelData

                    height: 56
                    width: fontList.width

                    Rectangle {
                        anchors.fill: parent
                        color: fontList.currentIndex === index ? Theme.color.bg3 : mouse.containsMouse ? Theme.color.bg2 : "transparent"
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            color: Theme.color.fg0
                            font.family: modelData
                            font.pixelSize: Theme.font.md
                            text: modelData
                        }

                        Text {
                            color: Theme.color.fg2
                            font.family: modelData
                            font.pixelSize: Theme.font.sm
                            text: "The quick brown fox jumps over the lazy dog"
                        }
                    }

                    MouseArea {
                        id: mouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            Config.setFont(modelData, Config.fontMono, Config.fontScale, Config.fontWeight);
                        }
                        onEntered: fontList.currentIndex = index
                    }
                }
            }
        }
    }

    // ── theme pack component ──────────────────────────────────────
    component PackRow: ColumnLayout {
        id: packRow

        property string packBaseName
        property var packData: ({})
        property string packPath
        property var variantKeys: []

        spacing: Theme.spacing.sm

        FileView {
            id: packFile

            blockLoading: true
            path: packRow.packPath.startsWith("file://") ? packRow.packPath.slice(7) : packRow.packPath
            watchChanges: true

            Component.onCompleted: reload()
            onFileChanged: reload()
            onLoaded: {
                try {
                    const parsed = JSON.parse(packFile.text());
                    packRow.packData = parsed;
                    packRow.variantKeys = parsed.variants ? Object.keys(parsed.variants) : [];
                } catch (e) {
                    console.warn("Failed to parse pack:", packRow.packPath, e);
                }
            }
        }

        Text {
            Layout.leftMargin: Theme.spacing.xs
            color: Theme.color.fg2
            font.family: Theme.font.ui
            font.pixelSize: Theme.font.sm
            font.weight: Theme.font.medium
            text: packRow.packData.pack ?? packRow.packBaseName
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacing.sm

            Repeater {
                model: packRow.variantKeys

                delegate: Rectangle {
                    id: variantCard

                    readonly property bool isActive: Config.currentTheme === packRow.packPath && Config.currentVariant === modelData
                    required property string modelData
                    readonly property var variantObj: packRow.packData.variants?.[modelData] ?? {}

                    border.color: isActive ? Theme.color.accent0 : Theme.color.border0
                    border.width: 2
                    color: Theme.color.bg2
                    height: 80
                    radius: 0
                    width: 140

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.spacing.sm

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Theme.spacing.xs

                            Repeater {
                                model: ["accent0", "fg0", "fg1", "bg0", "bg2"]

                                delegate: Rectangle {
                                    required property string modelData

                                    color: variantCard.variantObj.color?.[modelData] ?? Theme.color.bg3
                                    height: 14
                                    radius: 0
                                    width: 14
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: Theme.color.fg0
                            font.family: Theme.font.ui
                            font.pixelSize: Theme.font.sm
                            text: variantCard.variantObj.name ?? variantCard.modelData
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Config.setTheme(packRow.packPath, variantCard.modelData)
                    }
                }
            }
        }
    }
}
