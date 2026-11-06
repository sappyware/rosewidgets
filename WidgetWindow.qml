import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property string wid
    readonly property var cfg: Config.widgets[wid] || ({
    })
    readonly property var th: Theme.forWidget(cfg)
    readonly property bool md3: th.md3 === true
    readonly property string shapeKind: md3 && cfg.shape ? String(cfg.shape) : "rounded"
    readonly property real corner: cfg.corner !== undefined ? Number(cfg.corner) : th.radius
    readonly property var pp: Config.pos(wid)
    readonly property var ex: Config.size(wid)
    readonly property int pad: Config.cardPad
    readonly property int sp: 32
    readonly property var builtin: ({
        "clock": "Clock.qml",
        "music": "Music.qml",
        "calendar": "Calendar.qml",
        "stats": "Stats.qml",
        "weather": "Weather.qml",
        "network": "Network.qml"
    })
    readonly property bool glass: Config.glassOn && !Config.isMd3
    readonly property color glassC: Config.glassColor
    readonly property real glassT: Config.glassTint
    readonly property real natW: loader.item ? Math.max(1, loader.item.implicitWidth) : 120
    readonly property real natH: loader.item ? Math.max(1, loader.item.implicitHeight) : 60
    readonly property bool fluid: loader.item ? (loader.item.fluid === true || loader.item.responsive === true) : false

    function report() {
        Config.reportNatural(wid, natW, natH, fluid);
    }

    onNatWChanged: report()
    onNatHChanged: report()
    onFluidChanged: report()
    Component.onCompleted: report()
    screen: Config.monitor()
    implicitWidth: card.width + 2 * sp
    implicitHeight: card.height + 2 * sp
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "rosewidgets"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
    }

    margins {
        left: Math.round(pp.x) - sp
        top: Math.round(pp.y) - sp
    }

    Item {
        id: card

        x: win.sp
        y: win.sp
        width: win.ex.w > 0 ? win.ex.w : (loader.item ? loader.item.implicitWidth + 2 * win.pad : 120)
        height: win.ex.h > 0 ? win.ex.h : (loader.item ? loader.item.implicitHeight + 2 * win.pad : 80)
        onWidthChanged: Config.reportSize(win.wid, width, height)
        onHeightChanged: Config.reportSize(win.wid, width, height)
        Component.onCompleted: Config.reportSize(win.wid, width, height)

        RectangularShadow {
            anchors.fill: parent
            visible: win.shapeKind === "rounded"
            radius: win.corner
            blur: win.th.shadowBlur
            offset: Qt.vector2d(0, win.th.shadowY)
            color: win.th.shadow
        }

        MdShape {
            anchors.fill: parent
            kind: win.shapeKind
            radius: win.corner
            color: win.glass ? Qt.rgba(win.glassC.r, win.glassC.g, win.glassC.b, win.glassT) : win.th.bg
            strokeWidth: win.glass ? 1 : win.th.borderW
            strokeColor: win.glass ? Qt.rgba(1, 1, 1, 0.1) : win.th.border
        }

        Item {
            id: stage

            x: win.pad
            y: win.pad
            width: card.width - 2 * win.pad
            height: card.height - 2 * win.pad
            clip: true

            Loader {
                id: loader

                readonly property bool resp: item !== null && (item.responsive === true || (Config.autoTile && item.fluid === true))
                readonly property real iw: item ? Math.max(1, item.implicitWidth) : 1
                readonly property real ih: item ? Math.max(1, item.implicitHeight) : 1

                width: resp ? stage.width : iw
                height: resp ? stage.height : ih
                scale: resp ? 1 : Math.min(stage.width / iw, stage.height / ih)
                transformOrigin: Item.TopLeft
                x: resp ? 0 : (stage.width - iw * scale) / 2
                y: resp ? 0 : (stage.height - ih * scale) / 2
                source: win.builtin[win.cfg.type] ? Qt.resolvedUrl(win.builtin[win.cfg.type]) : "file://" + Config.dir + "/widgets/" + win.cfg.type + ".qml"
            }

        }

        Binding {
            target: loader.item
            property: "theme"
            value: win.th
            when: loader.item !== null
        }

        Binding {
            target: loader.item
            property: "options"
            value: win.cfg
            when: loader.item !== null
        }

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 320
            easing.type: Easing.OutCubic
        }

        NumberAnimation on scale {
            from: 0.92
            to: 1
            duration: 520
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }

    }

    mask: Region {
        item: card
    }

}
