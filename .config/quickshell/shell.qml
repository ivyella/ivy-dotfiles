//@ pragma ShellId ivyshell
//@ pragma UseQApplication

import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Overlays.CommandBar

import qs.Overlays.Launcher
import qs.Overlays.NotificationCard
import qs.Overlays.PowerMenu
import qs.Overlays.QuickPanel
import qs.Overlays.TrayMenu

import qs.Reusables.Components
import qs.Reusables.MdIcons
import qs.Reusables.Theme

import qs.Services
import qs.Services.Battery
import qs.Services.Config
import qs.Services.Notification
import qs.Services.Time

import qs.Surfaces.Bar
import qs.Surfaces.Wallpaper

ShellRoot {
    readonly property var _powerMenu: PowerMenu
    readonly property var _quickPanel: QuickPanel

    Launcher {}

    Bar {}

    CommandBar {}

    Notification {}

    Wallpaper {}
}
