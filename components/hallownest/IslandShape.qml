import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

Shape {
    id: root

    property real w
    property real h
    property real radius
    property real leftFillet: 14
    property real rightFillet: 14
    readonly property real r: Math.min(radius, h, w / 2)

    width: w + leftFillet + rightFillet
    height: h
    preferredRendererType: Shape.CurveRenderer

    Behavior on leftFillet {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on rightFillet {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    ShapePath {
        fillColor: Hallownest.void_
        strokeWidth: -1
        startX: 0
        startY: 0

        PathLine {
            x: root.width
            y: 0
        }
        PathArc {
            x: root.width - root.rightFillet
            y: root.rightFillet
            radiusX: root.rightFillet
            radiusY: root.rightFillet
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: root.leftFillet + root.w
            y: root.h - root.r
        }
        PathArc {
            x: root.leftFillet + root.w - root.r
            y: root.h
            radiusX: root.r
            radiusY: root.r
        }
        PathLine {
            x: root.leftFillet + root.r
            y: root.h
        }
        PathArc {
            x: root.leftFillet
            y: root.h - root.r
            radiusX: root.r
            radiusY: root.r
        }
        PathLine {
            x: root.leftFillet
            y: root.leftFillet
        }
        PathArc {
            x: 0
            y: 0
            radiusX: root.leftFillet
            radiusY: root.leftFillet
            direction: PathArc.Counterclockwise
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Hallownest.border
        strokeWidth: 1
        startX: 0
        startY: 0

        PathArc {
            x: root.leftFillet
            y: root.leftFillet
            radiusX: root.leftFillet
            radiusY: root.leftFillet
        }
        PathLine {
            x: root.leftFillet
            y: root.h - root.r
        }
        PathArc {
            x: root.leftFillet + root.r
            y: root.h
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: root.leftFillet + root.w - root.r
            y: root.h
        }
        PathArc {
            x: root.leftFillet + root.w
            y: root.h - root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: root.leftFillet + root.w
            y: root.rightFillet
        }
        PathArc {
            x: root.width
            y: 0
            radiusX: root.rightFillet
            radiusY: root.rightFillet
        }
    }
}
