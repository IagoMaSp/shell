import QtQuick
import QtQuick.Shapes

// Renders pixel art from rows of strings, where "#" is a filled cell
Shape {
    id: root

    property var rows: []
    property real pixelSize: 1
    property color color
    readonly property int columns: rows.reduce((max, row) => Math.max(max, row.length), 0)

    implicitWidth: columns * pixelSize
    implicitHeight: rows.length * pixelSize

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        strokeWidth: 0

        PathSvg {
            path: {
                const p = root.pixelSize;
                let d = "";
                for (let y = 0; y < root.rows.length; y++) {
                    const row = root.rows[y];
                    let x = 0;
                    while (x < row.length) {
                        if (row[x] !== "#") {
                            x++;
                            continue;
                        }
                        const start = x;
                        while (x < row.length && row[x] === "#")
                            x++;
                        d += `M${start * p} ${y * p}h${(x - start) * p}v${p}h${-(x - start) * p}z`;
                    }
                }
                return d || "M0 0";
            }
        }
    }
}
