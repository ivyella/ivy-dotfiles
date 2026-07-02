import QtQuick
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
// InnerCorner
// A single inverse rounded corner — the little filled shape that sits at the
// junction between a panel edge and the screen frame, making them look flush.
//
// At rotation 0 this draws a top-left inner corner (scoop faces top-left).
// Rotate 90/180/270 for the other three quadrants.
//
//   rotation: 0   → top-left inner corner    (panel on left,   frame on top)
//   rotation: 90  → top-right inner corner   (panel on right,  frame on top)
//   rotation: 180 → bottom-right inner corner(panel on right,  frame on bottom)
//   rotation: 270 → bottom-left inner corner (panel on left,   frame on bottom)
//
// The filled color should match whatever is *behind* the corner
// (typically the screen frame color or the panel bg).
//
// Properties:
//   radius — arc radius in pixels (should match the frame's corner radius)
//   color  — fill color
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    property color color: "black"
    property real radius: 10

    height: implicitHeight
    implicitHeight: radius

    // Item is exactly radius × radius so it can be positioned precisely
    implicitWidth: radius
    width: implicitWidth

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 8

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            // Path draws the filled wedge with a scooped arc.
            // At rotation 0: top-left quadrant.
            //   Start at top-right of the bounding box (0,0)→(radius,0)
            //   Arc counterclockwise to bottom-left (0,radius)
            //   Line back to origin

            PathMove {
                x: root.radius
                y: 0
            }

            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.radius
                radiusY: root.radius
                x: 0
                y: root.radius
            }

            PathLine {
                x: root.radius
                y: root.radius
            }

            PathLine {
                x: root.radius
                y: 0
            }
        }
    }
}
