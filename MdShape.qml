import QtQuick
import QtQuick.Shapes
import "shapes.js" as Sh

Item {
    id: root

    property string kind: "rounded"
    property var cycle: []
    property int cycleMs: 4000
    property int morphMs: 520
    property real radius: 16
    property color color: "white"
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property int idx: 0
    readonly property string eff: cycle.length > 0 ? cycle[idx % cycle.length] : kind
    readonly property bool poly: Sh.has(eff)
    property real t: 1
    property var fromR: []
    property var toR: []
    readonly property var pts: poly ? build() : []

    function build() {
        var n = toR.length - 1, out = [], w = width, h = height;
        if (n < 2 || fromR.length !== toR.length)
            return out;

        for (var i = 0; i <= n; i++) {
            var a = 2 * Math.PI * (i % n) / n;
            var r = fromR[i] + (toR[i] - fromR[i]) * t;
            out.push(Qt.point(w / 2 + r * Math.cos(a) * w / 2, h / 2 + r * Math.sin(a) * h / 2));
        }
        return out;
    }

    onEffChanged: {
        if (!Sh.has(eff))
            return ;

        var next = Sh.radii(eff);
        fromR = toR.length ? Sh.lerp(fromR, toR, t) : next;
        toR = next;
        t = 0;
        morph.restart();
    }
    Component.onCompleted: {
        if (Sh.has(eff)) {
            toR = Sh.radii(eff);
            fromR = toR;
        }
        morph.stop();
        t = 1;
    }

    NumberAnimation {
        id: morph

        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.morphMs
        easing.type: Easing.OutBack
        easing.overshoot: 1.7
    }

    Timer {
        interval: root.cycleMs
        repeat: true
        running: root.cycle.length > 1 && root.visible
        onTriggered: root.idx++
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.poly
        radius: root.kind === "pill" ? Math.min(width, height) / 2 : Math.min(root.radius, Math.min(width, height) / 2)
        color: root.color
        border.width: root.strokeWidth
        border.color: root.strokeColor
    }

    Shape {
        anchors.fill: parent
        visible: root.poly
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth > 0 ? root.strokeWidth : -1
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.pts
            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: 280
        }

    }

}
