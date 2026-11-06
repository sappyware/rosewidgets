import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: ov

    property bool panelOpen: false
    readonly property real minW: 100
    readonly property real minH: 60
    readonly property var th: Theme.cur
    readonly property int grid: Config.general.grid || 20
    readonly property real snapDist: 8
    property bool snapOn: true
    property real gx: -1
    property real gy: -1
    property string tileTarget: ""

    visible: Config.editMode
    screen: Config.monitor()
    color: "#40000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "rosewidgets-edit"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: {
        if (visible) {
            Config.scan();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Item {
        focus: true
        Keys.onEscapePressed: Config.editMode = false
    }

    Canvas {
        id: gridCanvas

        property int g: ov.grid

        anchors.fill: parent
        visible: !Config.autoTile
        onGChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: {
            if (visible) {
                requestPaint();
            }
        }
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.lineWidth = 1;
            for (var pass = 0; pass < 2; pass++) {
                ctx.beginPath();
                ctx.strokeStyle = pass === 1 ? "rgba(255,255,255,0.18)" : "rgba(255,255,255,0.07)";
                for (var i = 0, x = 0; x <= width; x += g, i++) {
                    if ((i % 5 === 0) !== (pass === 1))
                        continue;

                    ctx.moveTo(x + 0.5, 0);
                    ctx.lineTo(x + 0.5, height);
                }
                for (var j = 0, y = 0; y <= height; y += g, j++) {
                    if ((j % 5 === 0) !== (pass === 1))
                        continue;

                    ctx.moveTo(0, y + 0.5);
                    ctx.lineTo(width, y + 0.5);
                }
                ctx.stroke();
            }
        }
    }

    MouseArea {
        id: ma

        property string active: ""
        property var h: null
        property var sr: null
        property real sx: 0
        property real sy: 0
        property int curShape: Qt.ArrowCursor

        function hit(mx, my) {
            for (var i = Config.ids.length - 1; i >= 0; i--) {
                var id = Config.ids[i], r = Config.rect(id), e = 10, s = 6;
                if (mx < r.x - s || mx > r.x + r.w + s || my < r.y - s || my > r.y + r.h + s)
                    continue;

                if (Config.autoTile)
                    return {
                    "id": id,
                    "l": false,
                    "r": false,
                    "t": false,
                    "b": false
                };

                return {
                    "id": id,
                    "l": mx < r.x + e,
                    "r": mx > r.x + r.w - e,
                    "t": my < r.y + e,
                    "b": my > r.y + r.h - e
                };
            }
            return null;
        }

        function shapeFor(k) {
            if (!k)
                return Qt.ArrowCursor;

            if ((k.l && k.t) || (k.r && k.b))
                return Qt.SizeFDiagCursor;

            if ((k.r && k.t) || (k.l && k.b))
                return Qt.SizeBDiagCursor;

            if (k.l || k.r)
                return Qt.SizeHorCursor;

            if (k.t || k.b)
                return Qt.SizeVerCursor;

            return Qt.SizeAllCursor;
        }

        function targets(skipId) {
            var xs = [0, ov.width / 2, ov.width], ys = [0, ov.height / 2, ov.height];
            for (var i = 0; i < Config.ids.length; i++) {
                var id = Config.ids[i];
                if (id === skipId)
                    continue;

                var r = Config.rect(id);
                if (r.w <= 0 || r.h <= 0)
                    continue;

                xs.push(r.x, r.x + r.w / 2, r.x + r.w);
                ys.push(r.y, r.y + r.h / 2, r.y + r.h);
            }
            return {
                "xs": xs,
                "ys": ys
            };
        }

        function axisMove(start, len, list) {
            var edges = [start, start + len / 2, start + len], best = 0, guide = -1, bd = ov.snapDist + 0.001;
            for (var a = 0; a < edges.length; a++) for (var b = 0; b < list.length; b++) {
                var d = list[b] - edges[a];
                if (Math.abs(d) < bd) {
                    bd = Math.abs(d);
                    best = d;
                    guide = list[b];
                }
            }
            if (guide >= 0)
                return {
                "off": best,
                "guide": guide
            };

            var g = ov.grid, bg = ov.snapDist + 0.001, off = 0;
            var ends = [start, start + len];
            for (var c = 0; c < ends.length; c++) {
                var gd = Math.round(ends[c] / g) * g - ends[c];
                if (Math.abs(gd) < bg) {
                    bg = Math.abs(gd);
                    off = gd;
                }
            }
            return {
                "off": off,
                "guide": -1
            };
        }

        function edgeSnap(e, list) {
            var best = e, guide = -1, bd = ov.snapDist + 0.001;
            for (var b = 0; b < list.length; b++) {
                var d = Math.abs(list[b] - e);
                if (d < bd) {
                    bd = d;
                    best = list[b];
                    guide = list[b];
                }
            }
            if (guide >= 0)
                return {
                "v": best,
                "guide": guide
            };

            var g = ov.grid, gv = Math.round(e / g) * g;
            if (Math.abs(gv - e) <= ov.snapDist)
                return {
                "v": gv,
                "guide": -1
            };

            return {
                "v": e,
                "guide": -1
            };
        }

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: curShape
        onPressed: (m) => {
            var k = hit(m.x, m.y);
            h = k;
            active = k ? k.id : "";
            sr = k ? Config.rect(k.id) : null;
            sx = m.x;
            sy = m.y;
        }
        onPositionChanged: (m) => {
            if (!pressed) {
                curShape = shapeFor(hit(m.x, m.y));
                return ;
            }
            if (!active)
                return ;

            var dx = m.x - sx, dy = m.y - sy;
            if (Config.autoTile) {
                Config.drag = {
                    "id": active,
                    "x": sr.x + dx,
                    "y": sr.y + dy,
                    "w": 0,
                    "h": 0
                };
                var tg = Config.nearestTile(m.x, m.y);
                ov.tileTarget = tg !== active ? tg : "";
                return ;
            }
            var snap = ov.snapOn && !(m.modifiers & Qt.AltModifier);
            var T = snap ? targets(active) : {
                "xs": [],
                "ys": []
            };
            var gx = -1, gy = -1;
            if (!(h.l || h.r || h.t || h.b)) {
                var px = Math.max(0, sr.x + dx), py = Math.max(0, sr.y + dy);
                if (snap) {
                    var ax = axisMove(px, sr.w, T.xs), ay = axisMove(py, sr.h, T.ys);
                    px = Math.max(0, px + ax.off);
                    py = Math.max(0, py + ay.off);
                    gx = ax.guide;
                    gy = ay.guide;
                }
                ov.gx = gx;
                ov.gy = gy;
                Config.drag = {
                    "id": active,
                    "x": px,
                    "y": py,
                    "w": 0,
                    "h": 0
                };
                return ;
            }
            var L = sr.x, R = sr.x + sr.w, Tp = sr.y, B = sr.y + sr.h;
            if (h.l) {
                L = Math.max(0, Math.min(sr.x + dx, R - ov.minW));
                if (snap) {
                    var sl = edgeSnap(L, T.xs);
                    L = Math.max(0, Math.min(sl.v, R - ov.minW));
                    gx = sl.guide;
                }
            }
            if (h.r) {
                R = Math.max(L + ov.minW, sr.x + sr.w + dx);
                if (snap) {
                    var sR = edgeSnap(R, T.xs);
                    R = Math.max(L + ov.minW, sR.v);
                    gx = sR.guide;
                }
            }
            if (h.t) {
                Tp = Math.max(0, Math.min(sr.y + dy, B - ov.minH));
                if (snap) {
                    var st = edgeSnap(Tp, T.ys);
                    Tp = Math.max(0, Math.min(st.v, B - ov.minH));
                    gy = st.guide;
                }
            }
            if (h.b) {
                B = Math.max(Tp + ov.minH, sr.y + sr.h + dy);
                if (snap) {
                    var sb = edgeSnap(B, T.ys);
                    B = Math.max(Tp + ov.minH, sb.v);
                    gy = sb.guide;
                }
            }
            ov.gx = gx;
            ov.gy = gy;
            Config.drag = {
                "id": active,
                "x": L,
                "y": Tp,
                "w": R - L,
                "h": B - Tp,
                "resized": true
            };
        }
        onReleased: {
            var d = Config.drag;
            if (Config.autoTile) {
                if (active && ov.tileTarget)
                    Config.moveTile(active, ov.tileTarget);

                ov.tileTarget = "";
            } else if (active && d.id === active) {
                if (d.resized)
                    Config.setRect(active, d.x, d.y, d.w, d.h);
                else
                    Config.setPos(active, d.x, d.y);
            }
            Config.drag = ({
            });
            active = "";
            ov.gx = -1;
            ov.gy = -1;
        }
        onDoubleClicked: (m) => {
            var k = hit(m.x, m.y);
            if (k) {
                var r = Config.rect(k.id);
                Config.setRect(k.id, r.x, r.y, 0, 0);
            }
        }
    }

    Repeater {
        model: Config.ids

        Item {
            id: box

            required property string modelData
            readonly property var r: Config.rect(modelData)

            x: r.x
            y: r.y
            width: r.w
            height: r.h

            Rectangle {
                anchors.fill: parent
                radius: ov.th.radius
                color: "transparent"
                border.width: 2
                border.color: ov.th.accent
            }

            Rectangle {
                anchors.fill: parent
                radius: ov.th.radius
                color: ov.th.accent
                opacity: 0.25
                visible: ov.tileTarget === box.modelData
            }

            Repeater {
                model: Config.autoTile ? [] : [[0, 0], [1, 0], [0, 1], [1, 1]]

                Rectangle {
                    required property var modelData

                    width: 12
                    height: 12
                    radius: 6
                    color: "white"
                    border.width: 2
                    border.color: ov.th.accent
                    x: modelData[0] * box.width - 6
                    y: modelData[1] * box.height - 6
                }

            }

            Text {
                x: 4
                y: -22
                text: box.modelData
                color: "white"
                font.pixelSize: 12
                font.family: ov.th.font
            }

            Rectangle {
                x: box.width / 2 - 11
                y: -34
                width: 22
                height: 22
                radius: 11
                color: "#ff453a"

                Text {
                    anchors.centerIn: parent
                    text: "\u2715"
                    color: "white"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.removeWidget(box.modelData)
                }

            }

        }

    }

    Rectangle {
        visible: ov.gx >= 0
        x: ov.gx - 0.5
        y: 0
        width: 1
        height: ov.height
        color: ov.th.accent
    }

    Rectangle {
        visible: ov.gy >= 0
        y: ov.gy - 0.5
        x: 0
        height: 1
        width: ov.width
        color: ov.th.accent
    }

    Rectangle {
        width: hrow.width + 24
        height: 44
        radius: 22
        color: ov.th.bg
        border.width: 1
        border.color: ov.th.border

        anchors {
            top: parent.top
            topMargin: 22
            horizontalCenter: parent.horizontalCenter
        }

        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: hrow

            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: addT.width + 28
                height: 30
                radius: 15
                color: ov.th.accent

                Text {
                    id: addT

                    anchors.centerIn: parent
                    text: ov.panelOpen ? "\u2715  Close" : "+  Add widget"
                    color: ov.th.accent_fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ov.panelOpen = !ov.panelOpen
                }

            }

            Rectangle {
                width: tileT.width + 28
                height: 30
                radius: 15
                color: Config.autoTile ? ov.th.surface : "transparent"
                border.width: 1
                border.color: Config.autoTile ? ov.th.accent : ov.th.border

                Text {
                    id: tileT

                    anchors.centerIn: parent
                    text: Config.autoTile ? "Auto-tile: on" : "Auto-tile: off"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.setAutoTile(!Config.autoTile)
                }

            }

            Rectangle {
                visible: !Config.autoTile
                width: snapT.width + 28
                height: 30
                radius: 15
                color: ov.snapOn ? ov.th.surface : "transparent"
                border.width: 1
                border.color: ov.snapOn ? ov.th.accent : ov.th.border

                Text {
                    id: snapT

                    anchors.centerIn: parent
                    text: ov.snapOn ? "Snap: on" : "Snap: off"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ov.snapOn = !ov.snapOn
                }

            }

            Rectangle {
                width: styleT.width + 28
                height: 30
                radius: 15
                color: Config.isMd3 ? ov.th.surface : "transparent"
                border.width: 1
                border.color: Config.isMd3 ? ov.th.accent : ov.th.border

                Text {
                    id: styleT

                    anchors.centerIn: parent
                    text: Config.isMd3 ? "Style: Material 3" : "Style: Custom"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.setStyle(Config.isMd3 ? "custom" : "md3")
                }

            }

            Rectangle {
                visible: Config.isMd3
                width: modeT.width + 28
                height: 30
                radius: 15
                color: "transparent"
                border.width: 1
                border.color: ov.th.border

                Text {
                    id: modeT

                    anchors.centerIn: parent
                    text: Config.md3Mode === "dark" ? "Dark" : "Light"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.setMd3Mode(Config.md3Mode === "dark" ? "light" : "dark")
                }

            }

            Rectangle {
                visible: Config.isMd3
                width: cardT.width + 28
                height: 30
                radius: 15
                color: "transparent"
                border.width: 1
                border.color: ov.th.border

                Text {
                    id: cardT

                    anchors.centerIn: parent
                    text: "Card: " + Config.md3Card.charAt(0).toUpperCase() + Config.md3Card.slice(1)
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.setMd3Card(({
                        "filled": "elevated",
                        "elevated": "outlined",
                        "outlined": "filled"
                    })[Config.md3Card])
                }

            }

            Rectangle {
                visible: !Config.isMd3
                width: glassT.width + 28
                height: 30
                radius: 15
                color: Config.glassOn ? ov.th.surface : "transparent"
                border.width: 1
                border.color: Config.glassOn ? ov.th.accent : ov.th.border

                Text {
                    id: glassT

                    anchors.centerIn: parent
                    text: Config.glassOn ? "Glass: on" : "Glass: off"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.setGlass(!Config.glassOn)
                }

            }

            Rectangle {
                visible: Config.glassOn && !Config.isMd3
                width: blurT.width + 44
                height: 30
                radius: 15
                color: ov.th.surface
                border.width: 1
                border.color: ov.th.border

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "\u2212"
                        color: ov.th.text
                        font.pixelSize: 18
                        font.family: ov.th.font

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Config.setBlurRadius(Config.glassRadius - 4)
                        }

                    }

                    Text {
                        id: blurT

                        text: "Blur " + Math.round(Config.glassRadius)
                        color: ov.th.text
                        font.pixelSize: 13
                        font.family: ov.th.font
                    }

                    Text {
                        text: "+"
                        color: ov.th.text
                        font.pixelSize: 18
                        font.family: ov.th.font

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Config.setBlurRadius(Config.glassRadius + 4)
                        }

                    }

                }

            }

            Rectangle {
                visible: Config.glassOn && !Config.isMd3
                width: tintT.width + 44
                height: 30
                radius: 15
                color: ov.th.surface
                border.width: 1
                border.color: ov.th.border

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "\u2212"
                        color: ov.th.text
                        font.pixelSize: 18
                        font.family: ov.th.font

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Config.setBlurTint(Config.glassTint - 0.05)
                        }

                    }

                    Text {
                        id: tintT

                        text: "Tint " + Math.round(Config.glassTint * 100) + "%"
                        color: ov.th.text
                        font.pixelSize: 13
                        font.family: ov.th.font
                    }

                    Text {
                        text: "+"
                        color: ov.th.text
                        font.pixelSize: 18
                        font.family: ov.th.font

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: Config.setBlurTint(Config.glassTint + 0.05)
                        }

                    }

                }

            }

            Rectangle {
                width: doneT.width + 28
                height: 30
                radius: 15
                color: "transparent"
                border.width: 1
                border.color: ov.th.border

                Text {
                    id: doneT

                    anchors.centerIn: parent
                    text: "Done"
                    color: ov.th.text
                    font.pixelSize: 13
                    font.family: ov.th.font
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Config.editMode = false
                }

            }

        }

    }

    Text {
        visible: Config.autoTile
        text: "Drag a widget onto another to move it there"
        color: "white"
        opacity: 0.8
        font.pixelSize: 12
        font.family: ov.th.font

        anchors {
            top: parent.top
            topMargin: 74
            horizontalCenter: parent.horizontalCenter
        }

    }

    Rectangle {
        id: panel

        width: 300
        y: 84
        height: ov.height - 108
        x: ov.panelOpen ? ov.width - width - 20 : ov.width + 20
        radius: ov.th.radius
        color: ov.th.bg
        border.width: 1
        border.color: ov.th.border

        MouseArea {
            anchors.fill: parent
        }

        Column {
            spacing: 10

            anchors {
                fill: parent
                margins: 18
            }

            Text {
                text: "Add widget"
                color: ov.th.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                font.family: ov.th.font
            }

            Repeater {
                model: Config.allWidgets

                Rectangle {
                    required property var modelData

                    width: parent.width
                    height: 56
                    radius: 14
                    color: rowMa.containsMouse ? ov.th.surface : "transparent"
                    border.width: 1
                    border.color: ov.th.border

                    Column {
                        spacing: 1

                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: ov.th.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            font.family: ov.th.font
                        }

                        Text {
                            text: modelData.desc
                            color: ov.th.subtext
                            font.pixelSize: 12
                            font.family: ov.th.font
                        }

                    }

                    Text {
                        text: "+"
                        color: ov.th.accent
                        font.pixelSize: 22

                        anchors {
                            right: parent.right
                            rightMargin: 16
                            verticalCenter: parent.verticalCenter
                        }

                    }

                    MouseArea {
                        id: rowMa

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Config.addWidget(modelData.type)
                    }

                }

            }

            Item {
                width: 1
                height: 8
            }

            Text {
                text: Config.isMd3 ? "Color" : "Theme"
                color: ov.th.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                font.family: ov.th.font
            }

            Flow {
                visible: !Config.isMd3
                width: parent.width
                spacing: 8

                Repeater {
                    model: Config.themes

                    Rectangle {
                        required property string modelData
                        readonly property bool sel: modelData === Config.themeName

                        height: 30
                        width: chipT.width + 24
                        radius: 15
                        color: sel ? ov.th.accent : "transparent"
                        border.width: 1
                        border.color: ov.th.border

                        Text {
                            id: chipT

                            anchors.centerIn: parent
                            text: modelData
                            color: parent.sel ? ov.th.accent_fg : ov.th.text
                            font.pixelSize: 13
                            font.family: ov.th.font
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Config.setTheme(modelData)
                        }

                    }

                }

            }

            Flow {
                visible: Config.isMd3
                width: parent.width
                spacing: 8

                Rectangle {
                    readonly property bool sel: Config.md3Seed === "wallpaper"

                    height: 30
                    width: wpT.width + 24
                    radius: 15
                    color: sel ? ov.th.accent : "transparent"
                    border.width: 1
                    border.color: ov.th.border

                    Text {
                        id: wpT

                        anchors.centerIn: parent
                        text: "Wallpaper"
                        color: parent.sel ? ov.th.accent_fg : ov.th.text
                        font.pixelSize: 13
                        font.family: ov.th.font
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Config.setMd3Seed("wallpaper")
                    }

                }

                Repeater {
                    model: ["#6750A4", "#4285F4", "#1B8A5A", "#C2185B", "#E65100", "#00838F"]

                    Rectangle {
                        required property string modelData
                        readonly property bool sel: Config.md3Seed.toLowerCase() === modelData.toLowerCase()

                        width: 30
                        height: 30
                        radius: 15
                        color: modelData
                        border.width: sel ? 3 : 1
                        border.color: sel ? ov.th.text : ov.th.border

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Config.setMd3Seed(modelData)
                        }

                    }

                }

            }

        }

        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

}
