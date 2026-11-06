import QtQuick
import Quickshell

Item {
    id: root

    property var theme: ({
    })
    property var options: ({
    })
    readonly property bool md3: theme.md3 === true
    readonly property bool mon: (options.week_start || "monday") !== "sunday"
    readonly property string todayShape: md3 ? (options.today_shape || "cookie") : "circle"
    property int offset: 0
    readonly property real baseCw: 34
    readonly property real cw: width > 0 ? width / 7 : baseCw
    readonly property real ch: 30
    readonly property bool fluid: true
    readonly property var first: new Date(clk.date.getFullYear(), clk.date.getMonth() + offset, 1)
    readonly property var labels: mon ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
    readonly property var cells: {
        var out = [], f = first, t = clk.date;
        var sd = (f.getDay() + (mon ? 6 : 0)) % 7;
        for (var i = 0; i < 42; i++) {
            var d = new Date(f.getFullYear(), f.getMonth(), 1 - sd + i);
            out.push({
                "d": d.getDate(),
                "cur": d.getMonth() === f.getMonth(),
                "today": d.getFullYear() === t.getFullYear() && d.getMonth() === t.getMonth() && d.getDate() === t.getDate()
            });
        }
        return out;
    }

    onOffsetChanged: monthAnim.restart()
    implicitWidth: baseCw * 7
    implicitHeight: 56 + ch * 6

    ParallelAnimation {
        id: monthAnim

        NumberAnimation {
            target: grid
            property: "opacity"
            from: 0.1
            to: 1
            duration: 280
        }

        NumberAnimation {
            target: grid
            property: "y"
            from: 66
            to: 56
            duration: 380
            easing.type: Easing.OutCubic
        }

    }

    SystemClock {
        id: clk

        precision: SystemClock.Minutes
    }

    Item {
        width: parent.width
        height: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Tx {
                theme: root.theme
                role: "titleLarge"
                csize: 17
                cweight: Font.Bold
                text: Qt.formatDate(root.first, "MMMM")
                color: root.theme.accent
            }

            Tx {
                theme: root.theme
                role: "titleLarge"
                csize: 17
                text: Qt.formatDate(root.first, "yyyy")
                color: root.theme.subtext
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.offset = 0
            }

        }

        Row {
            spacing: root.md3 ? 6 : 14

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: [{
                    "g": "\u2039",
                    "d": -1
                }, {
                    "g": "\u203A",
                    "d": 1
                }]

                Item {
                    required property var modelData

                    width: root.md3 ? 28 : arrow.implicitWidth
                    height: root.md3 ? 28 : arrow.implicitHeight

                    MdButton {
                        visible: root.md3
                        anchors.fill: parent
                        th: root.theme
                        shape: "circle"
                        pressedShape: "squircle"
                        bg: root.theme.tonal
                        fg: root.theme.tonalFg
                        label: modelData.g
                        glyphSize: 20
                        onClicked: root.offset += modelData.d
                    }

                    Text {
                        id: arrow

                        visible: !root.md3
                        anchors.centerIn: parent
                        text: modelData.g
                        color: root.theme.text
                        font.pixelSize: 24
                        scale: tma.pressed ? 0.8 : 1

                        Behavior on scale {
                            SpringAnimation {
                                spring: 5
                                damping: 0.3
                                epsilon: 0.002
                            }

                        }

                    }

                    MouseArea {
                        id: tma

                        enabled: !root.md3
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: root.offset += modelData.d
                    }

                }

            }

        }

    }

    Row {
        y: 30

        Repeater {
            model: root.labels

            Tx {
                required property string modelData

                theme: root.theme
                role: "labelMedium"
                csize: 11
                cweight: Font.DemiBold
                width: root.cw
                height: 26
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: root.theme.subtext
            }

        }

    }

    Grid {
        id: grid

        y: 56
        columns: 7

        Repeater {
            model: root.cells

            Item {
                required property var modelData

                width: root.cw
                height: root.ch

                MdShape {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    kind: modelData.today ? root.todayShape : "pill"
                    cycle: modelData.today && root.md3 && !root.options.today_shape ? ["cookie", "sunny", "cookie6"] : []
                    cycleMs: 3500
                    color: modelData.today ? root.theme.accent : "transparent"
                }

                Tx {
                    theme: root.theme
                    anchors.centerIn: parent
                    role: "bodyMedium"
                    csize: 13
                    emph: modelData.today
                    cweight: modelData.today ? Font.Bold : Font.Normal
                    text: modelData.d
                    opacity: modelData.cur ? 1 : 0.35
                    color: modelData.today ? root.theme.accent_fg : root.theme.text
                }

            }

        }

    }

}
