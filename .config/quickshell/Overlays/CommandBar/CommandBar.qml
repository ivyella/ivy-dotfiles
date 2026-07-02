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

    property string currentPackPath: ""
    property var currentPackVariants: []

    // ── cursor tracking ──────────────────────────
    // cursorX is relative to commandBarWrapper so previewBox.x can use it directly
    property real cursorX: {
        // map from commandInput local space → commandBarWrapper space
        const pt = commandInput.mapToItem(commandBarWrapper, commandInput.cursorRectangle.x, 0);
        return pt.x;
    }
    property string ghostSuffix: ""

    // ── available commands ───────────────────────
    readonly property var knownCommands: [
        {
            name: "run",
            description: "usage: run {program name}"
        },
        {
            name: "theme",
            description: "usage: theme {pack} {variant}"
        },
        {
            name: "wallpaper",
            description: "usage: wallpaper {name}"
        },
        {
            name: "font",
            description: "usage: font {font name}"
        }
    ]
    readonly property var monoFont: Config.fontMono ?? Theme.font.mono

    // ── preview state ────────────────────────────
    property int previewBoxWidth: 280
    property int previewIndex: 0
    property var previewItems: []
    property string previewType: ""   // "commands" | "apps" | "wallpapers" | "fonts" | "themepacks" | "themevariants"
    property var selectedApp: null

    // ── font cache ───────────────────────────────
    property var systemFonts: []

    // ── theme-pack cache ─────────────────────────
    property var themePacksCache: ({})   // filePath → { variants: [string], variantsData: object }
    property int totalMatchCount: 0
    readonly property var uiFont: Config.fontUi ?? Theme.font.ui
    property bool variantsLoading: false

    // ────────────────────────────────────────────────────────────────
    //  executeCommand
    // ────────────────────────────────────────────────────────────────
    function executeCommand() {
        const parts = commandInput.text.trim().split(" ");
        const cmd = parts[0].toLowerCase();

        if (cmd === "run" || cmd === "launch") {
            if (selectedApp) {
                LauncherService.launch(selectedApp);
                CommandService.hide();
                return;
            }
            if (previewType === "apps" && previewItems.length > 0) {
                const app = previewItems[previewIndex];
                if (app) {
                    LauncherService.launch(app);
                    CommandService.hide();
                    return;
                }
            }
        }

        if (cmd === "theme") {
            if (parts.length >= 2) {
                const packPath = root.findPackPath(parts[1]);
                if (packPath && parts.length >= 3) {
                    Config.setTheme(packPath, parts[2]);
                    CommandService.hide();
                    return;
                }
            }
            CommandService.hide();
            return;
        }

        if (cmd === "wallpaper") {
            if (previewType === "wallpapers" && previewItems.length > 0) {
                Config.setWallpaper(previewItems[previewIndex].filePath);
                CommandService.hide();
                return;
            }
        }

        if (cmd === "font") {
            if (previewType === "fonts" && previewItems.length > 0) {
                const chosenFont = previewItems[previewIndex];
                Config.setFont(chosenFont, Config.fontMono, Config.fontScale, Config.fontWeight);
                CommandService.hide();
                return;
            }
        }

        CommandService.hide();
    }

    // ────────────────────────────────────────────────────────────────
    //  fillSelection
    // ────────────────────────────────────────────────────────────────
    function fillSelection() {
        if (previewType === "commands") {
            const cmd = previewItems[previewIndex];
            if (cmd) {
                commandInput.text = cmd.name + " ";
                commandInput.cursorPosition = commandInput.text.length;
            }
        } else if (previewType === "apps") {
            const app = previewItems[previewIndex];
            if (app) {
                const base = commandInput.text.split(" ")[0];
                commandInput.text = base + " " + app.name;
                commandInput.cursorPosition = commandInput.text.length;
                selectedApp = app;
            }
        } else if (previewType === "wallpapers") {
            const wallpaper = previewItems[previewIndex];
            if (wallpaper) {
                commandInput.text = "wallpaper " + wallpaper.name;
                commandInput.cursorPosition = commandInput.text.length;
            }
        } else if (previewType === "fonts") {
            const font = previewItems[previewIndex];
            if (font) {
                const base = commandInput.text.split(" ")[0];
                commandInput.text = base + " " + font;
                commandInput.cursorPosition = commandInput.text.length;
            }
        } else if (previewType === "themepacks") {
            const pack = previewItems[previewIndex];
            if (pack) {
                commandInput.text = "theme " + pack.name + " ";
                commandInput.cursorPosition = commandInput.text.length;
                root.currentPackPath = pack.filePath;
                if (root.themePacksCache[pack.filePath]) {
                    root.currentPackVariants = root.themePacksCache[pack.filePath].variants;
                    root.variantsLoading = false;
                } else {
                    root.variantsLoading = true;
                    packLoader.path = pack.filePath.startsWith("file://") ? pack.filePath.slice(7) : pack.filePath;
                    packLoader.reload();
                }
            }
        } else if (previewType === "themevariants") {
            const parts = commandInput.text.split(" ");
            const packName = parts[1] || "";
            const variantName = previewItems[previewIndex];
            if (variantName && !variantName.placeholder) {
                commandInput.text = "theme " + packName + " " + variantName;
                commandInput.cursorPosition = commandInput.text.length;
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    //  findPackPath  – resolve display name → file path
    // ────────────────────────────────────────────────────────────────
    function findPackPath(packName) {
        for (let i = 0; i < themePacksModel.count; i++) {
            const fname = themePacksModel.get(i, "fileName");
            const base = fname.replace(/\.json$/i, "");
            if (base.toLowerCase() === packName.toLowerCase())
                return themePacksModel.get(i, "filePath");
        }
        return "";
    }

    // ────────────────────────────────────────────────────────────────
    //  parseCommand  – drives all preview state from input text
    // ────────────────────────────────────────────────────────────────
    function parseCommand(text) {
        ghostSuffix = "";
        selectedApp = null;

        if (text.trim() === "") {
            previewType = "commands";
            previewItems = knownCommands;
            previewIndex = 0;
            updatePreviewBoxWidth();
            return;
        }

        const parts = text.split(" ");
        const cmd = parts[0].toLowerCase();
        const inArgPosition = parts.length > 1;

        // ── no argument yet: filter command names ──
        if (!inArgPosition) {
            const filtered = knownCommands.filter(c => c.name.startsWith(cmd));
            previewType = "commands";
            previewItems = filtered;
            previewIndex = 0;
            if (filtered.length > 0 && filtered[0].name !== cmd)
                ghostSuffix = filtered[0].name.slice(cmd.length);
            updatePreviewBoxWidth();
            return;
        }

        const arg = parts.slice(1).join(" ").toLowerCase();

        // ── run / launch ──────────────────────────
        if (cmd === "run" || cmd === "launch") {
            previewType = "apps";
            const sorted = LauncherService.apps.filter(a => arg === "" || a.name.toLowerCase().includes(arg)).sort((a, b) => {
                const aC = LauncherService.launchCounts[a.name] || 0;
                const bC = LauncherService.launchCounts[b.name] || 0;
                return bC !== aC ? bC - aC : a.name.localeCompare(b.name);
            });
            totalMatchCount = sorted.length;
            previewItems = sorted;
            previewIndex = 0;
            updatePreviewBoxWidth();
            if (sorted.length > 0 && arg !== "") {
                const m = sorted[0].name;
                if (m.toLowerCase().startsWith(arg))
                    ghostSuffix = m.slice(arg.length);
            }
            return;
        }

        // ── wallpaper ─────────────────────────────
        if (cmd === "wallpaper") {
            previewType = "wallpapers";
            const items = [];
            for (let i = 0; i < wallpaperModel.count; i++) {
                const fileName = wallpaperModel.get(i, "fileName");
                const filePath = wallpaperModel.get(i, "filePath");
                if (arg === "" || fileName.toLowerCase().includes(arg))
                    items.push({
                        name: fileName,
                        filePath: filePath
                    });
            }
            items.sort((a, b) => a.name.localeCompare(b.name));
            previewItems = items;
            totalMatchCount = items.length;
            previewIndex = 0;
            updatePreviewBoxWidth();
            if (items.length > 0 && arg !== "") {
                const m = items[0].name;
                if (m.toLowerCase().startsWith(arg))
                    ghostSuffix = m.slice(arg.length);
            }
            return;
        }

        // ── font ──────────────────────────────────
        if (cmd === "font") {
            previewType = "fonts";
            let fonts = root.systemFonts;
            if (arg !== "")
                fonts = fonts.filter(f => f.toLowerCase().includes(arg));
            previewItems = fonts;
            totalMatchCount = fonts.length;
            previewIndex = 0;
            updatePreviewBoxWidth();
            if (fonts.length > 0 && arg !== "") {
                const m = fonts[0];
                if (m.toLowerCase().startsWith(arg))
                    ghostSuffix = m.slice(arg.length);
            }
            return;
        }

        // ── theme ─────────────────────────────────
        if (cmd === "theme") {

            // "theme " or partial pack name (no trailing space yet)
            if (parts.length === 2) {
                const packFilter = parts[1].toLowerCase();
                previewType = "themepacks";
                const packs = [];
                for (let i = 0; i < themePacksModel.count; i++) {
                    const base = themePacksModel.get(i, "fileName").replace(/\.json$/i, "");
                    if (packFilter === "" || base.toLowerCase().startsWith(packFilter)) {
                        packs.push({
                            name: base,
                            filePath: themePacksModel.get(i, "filePath")
                        });
                    }
                }
                packs.sort((a, b) => a.name.localeCompare(b.name));
                previewItems = packs;
                totalMatchCount = packs.length;
                previewIndex = 0;
                if (packs.length > 0 && packFilter !== "") {
                    const m = packs[0].name;
                    if (m.toLowerCase().startsWith(packFilter))
                        ghostSuffix = m.slice(packFilter.length);
                }
                updatePreviewBoxWidth();
                return;
            }

            // ── variant stage ──
            const packName = parts[1];
            const packPath = root.findPackPath(packName);

            if (!packPath) {
                previewType = "themevariants";
                previewItems = [];
                totalMatchCount = 0;
                updatePreviewBoxWidth();
                return;
            }

            if (!root.themePacksCache[packPath]) {
                root.currentPackPath = packPath;
                root.variantsLoading = true;
                root.currentPackVariants = [];
                packLoader.path = packPath.startsWith("file://") ? packPath.slice(7) : packPath;
                packLoader.reload();
                previewType = "themevariants";
                previewItems = [
                    {
                        name: "Loading variants…",
                        placeholder: true
                    }
                ];
                totalMatchCount = 1;
                previewIndex = 0;
                updatePreviewBoxWidth();
                return;
            }

            root.currentPackVariants = root.themePacksCache[packPath].variants;
            root.currentPackPath = packPath;
            root.variantsLoading = false;

            const variantFilter = parts.length >= 3 ? parts.slice(2).join(" ").toLowerCase() : "";
            let variants = root.currentPackVariants;
            if (variantFilter !== "")
                variants = variants.filter(v => v.toLowerCase().includes(variantFilter));

            previewType = "themevariants";
            previewItems = variants;
            totalMatchCount = variants.length;
            previewIndex = 0;
            updatePreviewBoxWidth();
            if (variants.length > 0 && variantFilter !== "") {
                const m = variants[0];
                if (m.toLowerCase().startsWith(variantFilter))
                    ghostSuffix = m.slice(variantFilter.length);
            }
            return;
        }

        // ── unknown command ───────────────────────
        previewType = "";
        previewItems = [];
        totalMatchCount = 0;
        updatePreviewBoxWidth();
    }

    // ────────────────────────────────────────────────────────────────
    //  updatePreviewBoxWidth
    // ────────────────────────────────────────────────────────────────
    function updatePreviewBoxWidth() {
        let maxW = 0;

        if (previewType === "wallpapers") {
            textMetrics.font = uiFont;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i].filePath;
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
        } else if (previewType === "apps") {
            textMetrics.font = uiFont;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i].name;
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
        } else if (previewType === "fonts") {
            textMetrics.font = uiFont;
            textMetrics.font.pixelSize = Theme.font.sm;
            textMetrics.text = "The quick brown fox jumps over the lazy dog";
            maxW = textMetrics.width;
            textMetrics.font.pixelSize = Theme.font.md;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i];
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
            maxW += 20;
        } else if (previewType === "themepacks") {
            textMetrics.font = uiFont;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i].name;
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
        } else if (previewType === "themevariants") {
            textMetrics.font = uiFont;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i].name || previewItems[i];
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
            // 5 swatches × 14 px + 4 gaps × 4 px
            maxW += 5 * 14 + 4 * 4;
        } else {
            // commands (mono font)
            textMetrics.font = monoFont;
            for (let i = 0; i < previewItems.length; i++) {
                textMetrics.text = previewItems[i].name;
                if (textMetrics.width > maxW)
                    maxW = textMetrics.width;
            }
        }

        const padding = Theme.icon.md + Theme.padding.md * 2 + 40;
        const maxAllowed = root.width - Theme.spacing.lg * 2 - (wallpaperPreview.visible ? wallpaperPreview.width + wallpaperPreview.anchors.leftMargin : 0);
        previewBoxWidth = Math.min(Math.max(maxW + padding, 280), maxAllowed);
    }

    // ────────────────────────────────────────────────────────────────
    //  Window / layer-shell config
    // ────────────────────────────────────────────────────────────────
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: CommandService.visible

    onVisibleChanged: {
        if (visible) {
            commandInput.text = "";
            previewIndex = 0;
            previewItems = [];
            previewType = "";
            ghostSuffix = "";
            systemFonts = Qt.fontFamilies().sort((a, b) => a.localeCompare(b, undefined, {
                    sensitivity: "base"
                }));
            focusTimer.start();
        }
    }

    // ────────────────────────────────────────────────────────────────
    //  Data models
    // ────────────────────────────────────────────────────────────────
    FolderListModel {
        id: themePacksModel

        folder: "file://" + Quickshell.env("HOME") + "/.config/ivylink/themes/colors/"
        nameFilters: ["*.json"]
    }

    FileView {
        id: packLoader

        blockLoading: true
        path: ""

        onLoaded: {
            try {
                const parsed = JSON.parse(packLoader.text());
                const vKeys = parsed.variants ? Object.keys(parsed.variants) : [];
                root.currentPackVariants = vKeys;
                root.themePacksCache[root.currentPackPath] = {
                    variants: vKeys,
                    variantsData: parsed.variants
                };
            } catch (e) {
                console.warn("Failed to parse theme pack:", root.currentPackPath, e);
                root.currentPackVariants = [];
            }
            root.variantsLoading = false;
            root.parseCommand(commandInput.text);
        }
    }

    TextMetrics {
        id: textMetrics
    }

    FolderListModel {
        id: wallpaperModel

        folder: "file://" + Quickshell.env("HOME") + "/ivyos/ivyshell/themes/wallpapers/"
        nameFilters: ["*.png", "*.jpg", "*.jpeg"]
    }

    // ────────────────────────────────────────────────────────────────
    //  Anchors / focus
    // ────────────────────────────────────────────────────────────────
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

        onTriggered: {
            commandInput.forceActiveFocus();
            root.parseCommand("");
        }
    }

    MouseArea {
        acceptedButtons: Qt.AllButtons
        anchors.fill: parent
        hoverEnabled: true
    }

    // ────────────────────────────────────────────────────────────────
    //  Main layout wrapper
    // ────────────────────────────────────────────────────────────────
    Rectangle {
        id: commandBarWrapper

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Theme.spacing.lg
        anchors.right: parent.right
        clip: false
        color: "transparent"

        // ── wallpaper live-preview (right of previewBox) ──────────
        Rectangle {
            id: wallpaperPreview

            anchors.bottom: previewBox.bottom
            anchors.left: previewBox.right
            anchors.leftMargin: Theme.spacing.sm
            border.color: Theme.color.border0
            border.width: 1
            clip: true
            color: Theme.color.bg1
            height: 240
            radius: 0
            visible: root.previewType === "wallpapers" && root.previewItems.length > 0
            width: 426

            Image {
                anchors.fill: parent
                anchors.margins: 4
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: (root.previewItems.length > 0 && root.previewIndex < root.previewItems.length) ? root.previewItems[root.previewIndex].filePath : ""
            }
        }

        // ── command bar ───────────────────────────────────────────
        Rectangle {
            id: commandBar

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            border.color: Theme.color.border0
            border.width: 1
            color: Theme.color.bg0
            implicitHeight: 42
            radius: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.padding.lg
                anchors.rightMargin: Theme.padding.lg

                Text {
                    color: Theme.color.accent0
                    font.family: root.monoFont
                    font.pixelSize: Theme.font.md
                    text: ">> "
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: commandInput.implicitHeight

                    // ghost autocomplete suffix
                    Text {
                        id: ghostText

                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.color.fg2
                        font.family: root.monoFont
                        font.pixelSize: Theme.font.md
                        opacity: 0.45
                        text: root.ghostSuffix
                        visible: root.ghostSuffix !== ""
                        x: commandInput.positionToRectangle(commandInput.cursorPosition).x
                    }

                    TextInput {
                        id: commandInput

                        anchors.fill: parent
                        color: Theme.color.fg0
                        font.family: root.monoFont
                        font.pixelSize: Theme.font.md

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                CommandService.hide();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                root.fillSelection();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && root.previewItems.length > 0) {
                                root.previewIndex = Math.min(root.previewIndex + 1, root.previewItems.length - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up && root.previewItems.length > 0) {
                                root.previewIndex = Math.max(root.previewIndex - 1, 0);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.executeCommand();
                                event.accepted = true;
                            }
                        }
                        onTextChanged: root.parseCommand(text)
                    }
                }

                // result count indicator
                Text {
                    color: Theme.color.fg2
                    font.family: root.monoFont
                    font.pixelSize: Theme.font.sm
                    text: {
                        const counted = ["apps", "wallpapers", "fonts", "themepacks", "themevariants"];
                        if (counted.indexOf(root.previewType) !== -1 && root.totalMatchCount > 0)
                            return "[" + (root.previewIndex + 1) + "/" + root.totalMatchCount + "]";
                        return "";
                    }
                }
            }
        }

        // ── preview list ──────────────────────────────────────────
        Rectangle {
            id: previewBox

            readonly property int itemHeight: root.previewType === "fonts" ? 56 : 40
            readonly property int maxItems: 10

            anchors.bottom: commandBar.top
            anchors.bottomMargin: Theme.spacing.sm
            border.color: Theme.color.bg3
            border.width: 1
            clip: true
            color: Theme.color.bg1
            height: Math.min(root.previewItems.length, maxItems) * itemHeight
            radius: 0
            visible: root.previewItems.length > 0
            width: root.previewBoxWidth

            // Position under the cursor, clamped to stay on screen.
            // cursorX is already in commandBarWrapper space so no extra offset needed.
            x: {
                let totalWidth = width;
                if (wallpaperPreview.visible)
                    totalWidth += wallpaperPreview.width + wallpaperPreview.anchors.leftMargin;
                const maxX = commandBarWrapper.width - totalWidth;
                return Math.max(0, Math.min(root.cursorX, maxX));
            }

            ListView {
                id: previewList

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                currentIndex: root.previewIndex
                model: root.previewItems

                delegate: Item {
                    id: previewItem

                    required property int index
                    readonly property bool isSelected: previewList.currentIndex === index
                    required property var modelData

                    height: previewBox.itemHeight
                    width: previewList.width

                    Rectangle {
                        anchors.fill: parent
                        color: previewItem.isSelected ? Theme.color.bg3 : previewMouse.containsMouse ? Theme.color.bg2 : "transparent"
                    }

                    // ── font preview ──────────────────────────────
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.md
                        anchors.rightMargin: Theme.padding.md
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        visible: root.previewType === "fonts"

                        Text {
                            color: previewItem.isSelected ? Theme.color.fg0 : Theme.color.fg1
                            font.family: previewItem.modelData
                            font.pixelSize: Theme.font.md
                            text: previewItem.modelData
                        }

                        Text {
                            color: Theme.color.fg2
                            font.family: previewItem.modelData
                            font.pixelSize: Theme.font.sm
                            text: "The quick brown fox jumps over the lazy dog"
                        }
                    }

                    // ── theme variant: swatches + name ────────────
                    RowLayout {
                        // Resolve the five swatch colors into a local property so the
                        // inner Repeater's own `modelData` doesn't shadow the outer one.
                        readonly property var swatchColors: {
                            const item = previewItem.modelData;
                            if (!item || item.placeholder)
                                return [];
                            const cache = root.themePacksCache[root.currentPackPath];
                            if (!cache || !cache.variantsData)
                                return [];
                            const vObj = cache.variantsData[item] || {};
                            const source = vObj.color || vObj;
                            return ["accent0", "fg0", "fg1", "bg0", "bg2"].map(k => source[k] ?? Theme.color.bg3);
                        }

                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.md
                        anchors.rightMargin: Theme.padding.md
                        spacing: 12
                        visible: root.previewType === "themevariants"

                        Row {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            visible: {
                                const item = previewItem.modelData;
                                return item && !item.placeholder;
                            }

                            Repeater {
                                // Use the resolved swatchColors property – not modelData –
                                // so the delegate's own modelData refers to each hex string.
                                model: parent.parent.swatchColors

                                delegate: Rectangle {
                                    required property var modelData   // each hex color string

                                    color: modelData
                                    height: 14
                                    radius: 10
                                    width: 14
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            color: previewItem.isSelected ? Theme.color.fg0 : Theme.color.fg1
                            font.family: root.uiFont
                            font.pixelSize: Theme.font.md
                            text: previewItem.modelData.name || previewItem.modelData
                        }
                    }

                    // ── theme pack: name only ─────────────────────
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.md
                        anchors.rightMargin: Theme.padding.md
                        color: previewItem.isSelected ? Theme.color.fg0 : Theme.color.fg1
                        font.family: root.uiFont
                        font.pixelSize: Theme.font.md
                        text: previewItem.modelData.name ?? ""
                        verticalAlignment: Text.AlignVCenter
                        visible: root.previewType === "themepacks"
                    }

                    // ── apps / wallpapers / commands ──────────────
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.md
                        anchors.rightMargin: Theme.padding.md
                        spacing: 12
                        visible: root.previewType !== "fonts" && root.previewType !== "themepacks" && root.previewType !== "themevariants"

                        Image {
                            asynchronous: true
                            height: Theme.icon.md
                            source: {
                                if (root.previewType === "apps")
                                    return LauncherService.iconFor(previewItem.modelData);
                                if (root.previewType === "wallpapers")
                                    return previewItem.modelData.filePath;
                                return "";
                            }
                            sourceSize: Qt.size(Theme.icon.md, Theme.icon.md)
                            visible: root.previewType === "apps" || root.previewType === "wallpapers"
                            width: Theme.icon.md
                        }

                        Column {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                color: previewItem.isSelected ? Theme.color.fg0 : Theme.color.fg1
                                elide: Text.ElideRight
                                font.family: root.previewType === "commands" ? root.monoFont : root.uiFont
                                font.pixelSize: Theme.font.md
                                text: previewItem.modelData.name !== undefined ? previewItem.modelData.name : previewItem.modelData
                            }

                            Text {
                                color: Theme.color.fg2
                                elide: Text.ElideRight
                                font.family: root.uiFont
                                font.pixelSize: Theme.font.sm
                                text: root.previewType === "wallpapers" ? previewItem.modelData.filePath : (previewItem.modelData.description ?? "")
                                visible: text !== ""
                            }
                        }
                    }

                    MouseArea {
                        id: previewMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            root.previewIndex = previewItem.index;
                            if (root.previewType === "apps")
                                root.selectedApp = previewItem.modelData;
                            root.fillSelection();
                            commandInput.forceActiveFocus();
                        }
                        onEntered: root.previewIndex = previewItem.index
                    }
                }
            }
        }
    }
}
