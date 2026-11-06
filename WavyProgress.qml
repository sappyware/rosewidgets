import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real value: 0
    property bool playing: true
    property bool wavy: true
    property color activeColor: "white"
    property color trackColor: "gray"
    property color thumbColor: activeColor
    property real thickness: 4
    property real amp: 2.6
    property real wavelength: 26
    property real gap: 6
    property real phase: 0
    property real ampNow: playing && wavy ? amp : 0
    property real dragV: 0
    readonly property bool dragging: ma.pressed
    property real disp: dragging ? dragV : Math.max(0, Math.min(1, value))
    readonly property real tx: width * disp
    readonly property real thumbW: ma.pressed ? 2 : 4
    readonly property var wave: build(tx - gap - thumbW / 2, ampNow, phase)

    signal seek(real f)

    function build(xe, a, ph) {
        var out = [], y0 = height / 2, x0 = thickness / 2;
        if (xe <= x0) {
            out.push(Qt.point(x0, y0));
            out.push(Qt.point(x0 + 0.01, y0));
            return out;
        }
        for (var x = x0; x < xe; x += 2) out.push(Qt.point(x, y0 + a * Math.sin(x / wavelength * 2 * Math.PI - ph)))
        out.push(Qt.point(xe, y0 + a * Math.sin(xe / wavelength * 2 * Math.PI - ph)));
        return out;
    }

    implicitHeight: 18

    Rectangle {
        x: Math.min(root.width, root.tx + root.thumbW / 2 + root.gap)
        y: (root.height - height) / 2
        width: Math.max(0, root.width - x - root.thickness / 2)
        height: root.thickness * 0.8
        radius: height / 2
        color: root.trackColor
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.activeColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.wave
            }

        }

    }

    Rectangle {
        x: Math.max(0, Math.min(root.width - width, root.tx - width / 2))
        y: (root.height - height) / 2
        width: root.thumbW
        height: root.height - 2
        radius: width / 2
        color: root.thumbColor

        Behavior on width {
            SpringAnimation {
                spring: 6
                damping: 0.4
                epsilon: 0.05
            }

        }

    }

    MouseArea {
        id: ma

        function f(x) {
            return Math.max(0, Math.min(1, x / width));
        }

        anchors.fill: parent
        onPressed: (m) => {
            root.dragV = f(m.x);
            root.seek(root.dragV);
        }
        onPositionChanged: (m) => {
            if (pressed) {
                root.dragV = f(m.x);
                root.seek(root.dragV);
            }
        }
    }

    Behavior on ampNow {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }

    }

    Behavior on disp {
        enabled: !root.dragging

        NumberAnimation {
            duration: 900
        }

    }

    NumberAnimation on phase {
        from: 0
        to: 2 * Math.PI
        duration: 1500
        loops: Animation.Infinite
        running: root.playing && root.wavy && root.visible && root.width > 0
    }

}
