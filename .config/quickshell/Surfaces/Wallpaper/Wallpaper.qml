pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Services.Config

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        id: wpShell

        required property var modelData

        exclusionMode: ExclusionMode.Ignore
        layer: WlrLayer.Background
        namespace: "wallpaper"
        screen: modelData

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            source: Config.currentWallpaper
        }
    }
}
