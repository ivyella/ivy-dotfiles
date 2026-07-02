import QtQuick
import qs.Reusables.Theme

Text {
    id: root

    property real fill: 1
    property real iconSize: 16

    color: Theme.color.fg1
    renderType: Text.NativeRendering

    font {
        family: "Material Symbols Rounded"
        hintingPreference: Font.PreferNoHinting
        pixelSize: iconSize
        variableAxes: ({
                "FILL": fill.toFixed(1),
                "opsz": iconSize
            })
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * fill
    }
}
