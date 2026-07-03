pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real borderRadius: 12
    readonly property string configPath: Quickshell.env("HOME") + "/.config/ivyshell/config.json"

    // ── Theme ─────────────────────────────────────────────────────────────────
    property string currentTheme: "file://" + Quickshell.env("HOME") + "/ivy-dotfiles/.config/ivylink/themes/colors/IvyTheme.json"
    property string currentVariant: "default"
    property string currentWallpaper: "file://" + Quickshell.env("HOME") + "/ivy-dotfiles/wallpapers/a_group_of_trees_with_green_leaves.jpg"
    property string fontMono: "JetBrains Mono"
    property real fontScale: 1.0

    // ── Font ──────────────────────────────────────────────────────────────────
    property string fontUi: "JetBrains Mono"
    property int fontWeight: 400
    readonly property var fonts: enumerateFonts()

    // ── Night Light ───────────────────────────────────────────────────────────
    property int nightLightTemp: 3500

    // ── UI ────────────────────────────────────────────────────────────────────
    property real uiScale: 1.0

    function enumerateFonts() {
        const keywords = ["thin", "light", "regular", "medium", "semibold", "bold", "extrabold", "black", "italic", "oblique", "condensed", "expanded", "narrow", "wide", "heavy", "ultra"];

        const seen = new Set();
        const fonts = [];

        for (const name of Qt.fontFamilies()) {
            if (name.startsWith("."))
                continue;
            const lower = name.toLowerCase();

            const isVariant = keywords.some(k => {
                const idx = lower.lastIndexOf(" " + k);
                return idx !== -1 && idx >= lower.length - k.length - 1;
            });

            if (isVariant)
                continue;
            if (seen.has(lower))
                continue;
            seen.add(lower);
            fonts.push(name);
        }

        fonts.sort();

        return fonts;
    }

    function save() {
        adapter.theme = root.currentTheme;
        adapter.variant = root.currentVariant;
        adapter.wallpaper = root.currentWallpaper;
        adapter.font = {
            ui: root.fontUi,
            mono: root.fontMono,
            scale: root.fontScale,
            weight: root.fontWeight
        };
        adapter.uiScale = root.uiScale;
        adapter.borderRadius = root.borderRadius;
        adapter.nightLight = {
            temp: root.nightLightTemp
        };
        file.writeAdapter();
    }

    function setBorderRadius(val) {
        root.borderRadius = val;
        save();
    }

    function setFont(ui, mono, scale, weight) {
        root.fontUi = ui;
        root.fontMono = mono;
        root.fontScale = scale;
        root.fontWeight = weight;
        save();
    }

    function setTheme(path, variant) {
        root.currentTheme = path;
        root.currentVariant = variant;
        save();
    }

    function setUiScale(val) {
        root.uiScale = val;
        save();
    }

    function setWallpaper(path) {
        root.currentWallpaper = path;
        save();
    }

    FileView {
        id: file

        blockLoading: true
        path: root.configPath

        Component.onCompleted: reload()
        onLoadFailed: root.save()
        onLoaded: {
            if (adapter.theme)
                root.currentTheme = adapter.theme;
            if (adapter.variant)
                root.currentVariant = adapter.variant;
            if (adapter.wallpaper)
                root.currentWallpaper = adapter.wallpaper;

            if (adapter.font) {
                if (adapter.font.ui)
                    root.fontUi = adapter.font.ui;
                if (adapter.font.mono)
                    root.fontMono = adapter.font.mono;
                if (adapter.font.scale)
                    root.fontScale = adapter.font.scale;
                if (adapter.font.weight)
                    root.fontWeight = adapter.font.weight;
            }

            if (adapter.uiScale)
                root.uiScale = adapter.uiScale;
            if (adapter.borderRadius)
                root.borderRadius = adapter.borderRadius;

            if (adapter.nightLight) {
                if (adapter.nightLight.temp)
                    root.nightLightTemp = adapter.nightLight.temp;
            }
        }

        JsonAdapter {
            id: adapter

            property real borderRadius
            property var font
            property var nightLight
            property string theme
            property real uiScale
            property string variant
            property string wallpaper
        }
    }
}
