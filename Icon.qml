import QtQuick

Canvas {
    id: c

    property string kind: "play"
    property color color: "white"

    onColorChanged: requestPaint()
    onKindChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var g = getContext("2d");
        g.reset();
        g.scale(width / 24, height / 24);
        g.fillStyle = c.color;
        g.strokeStyle = c.color;
        g.lineWidth = 1.7;
        g.lineJoin = "round";
        g.lineCap = "round";
        if (kind === "play") {
            poly([[8.9, 5.9], [8.9, 18.1], [18.3, 12]]);
        } else if (kind === "pause") {
            rect(6.9, 5.9, 2.2, 12.2);
            rect(14.9, 5.9, 2.2, 12.2);
        } else if (kind === "prev") {
            rect(6.9, 6.9, 0.2, 10.2);
            poly([[10.4, 12], [17.2, 17.1], [17.2, 6.9]]);
        } else if (kind === "next") {
            poly([[6.8, 6.9], [6.8, 17.1], [13.6, 12]]);
            rect(16.9, 6.9, 0.2, 10.2);
        }
    }

    function poly(p) {
        g.beginPath();
        g.moveTo(p[0][0], p[0][1]);
        for (var i = 1; i < p.length; i++) g.lineTo(p[i][0], p[i][1])
        g.closePath();
        g.fill();
        g.stroke();
    }

    function rect(x, y, w, h) {
        poly([[x, y], [x + w, y], [x + w, y + h], [x, y + h]]);
    }

}
