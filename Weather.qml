import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: ({
    })
    property var options: ({
    })
    property var data: null
    property string error: ""
    readonly property bool md3: theme.md3 === true
    readonly property bool imp: options.units === "imperial"
    readonly property string loc: options.location || ""
    readonly property string glyphShape: options.glyph_shape || "sunny"
    readonly property var gl: glyph(data ? data.desc : "")
    readonly property bool fluid: true

    function glyph(desc) {
        var d = (desc || "").toLowerCase();
        if (d.indexOf("thunder") >= 0)
            return ["\u26A1\uFE0E", theme.yellow];

        if (/snow|sleet|blizzard|ice/.test(d))
            return ["\u2744\uFE0E", theme.teal];

        if (/rain|drizzle|shower/.test(d))
            return ["\u2602\uFE0E", theme.blue];

        if (/fog|mist|haze/.test(d))
            return ["\u224B", theme.subtext];

        if (/sun|clear/.test(d))
            return ["\u2600\uFE0E", theme.yellow];

        return ["\u2601\uFE0E", theme.subtext];
    }

    function parse(t) {
        try {
            var j = JSON.parse(t), c = j.current_condition[0];
            root.data = {
                "area": j.nearest_area[0].areaName[0].value,
                "temp": imp ? c.temp_F : c.temp_C,
                "feels": imp ? c.FeelsLikeF : c.FeelsLikeC,
                "desc": c.weatherDesc[0].value,
                "hum": c.humidity,
                "wind": imp ? c.windspeedMiles + " mph" : c.windspeedKmph + " km/h",
                "days": j.weather.slice(0, 3).map(function(w) {
                    return {
                        "date": w.date,
                        "hi": imp ? w.maxtempF : w.maxtempC,
                        "lo": imp ? w.mintempF : w.mintempC
                    };
                })
            };
            root.error = "";
        } catch (e) {
            if (!root.data)
                root.error = "No data";

        }
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;

    }

    implicitWidth: 300
    implicitHeight: 196
    onImpChanged: refresh()
    onLocChanged: refresh()

    Process {
        id: proc

        command: ["curl", "-sf", "-m", "10", "https://wttr.in/" + encodeURIComponent(root.loc) + "?format=j1"]
        onExited: (code) => {
            if (code !== 0 && !root.data)
                root.error = "Offline";

        }

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }

    }

    Timer {
        interval: 1.8e+06
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 500
        running: true
        onTriggered: root.refresh()
    }

    Tx {
        theme: root.theme
        anchors.centerIn: parent
        visible: root.data === null
        role: "bodyLarge"
        csize: 14
        text: root.error || "Loading\u2026"
        color: root.theme.subtext
    }

    Column {
        width: parent.width
        opacity: root.data !== null ? 1 : 0
        visible: opacity > 0.01
        spacing: 4

        Item {
            width: parent.width
            height: 78

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Tx {
                    theme: root.theme
                    role: "labelLarge"
                    csize: 13
                    cweight: Font.DemiBold
                    text: root.data ? root.data.area : ""
                    color: root.theme.subtext
                }

                Tx {
                    theme: root.theme
                    role: root.md3 ? "displayMedium" : "displayLarge"
                    csize: 52
                    cweight: Font.Light
                    text: root.data ? root.data.temp + "\u00B0" : ""
                }

            }

            Item {
                width: root.md3 ? 72 : glyphT.implicitWidth
                height: root.md3 ? 72 : glyphT.implicitHeight

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                MdShape {
                    anchors.fill: parent
                    visible: root.md3
                    kind: root.glyphShape
                    cycle: root.options.glyph_shape ? [] : ["sunny", "cookie", "flower", "scallop"]
                    cycleMs: 4500
                    color: root.theme.accentC
                }

                Text {
                    id: glyphT

                    anchors.centerIn: parent
                    text: root.gl[0]
                    color: root.md3 ? root.theme.accentCfg : root.gl[1]
                    font.pixelSize: root.md3 ? 38 : 54
                }

            }

        }

        Tx {
            theme: root.theme
            role: "titleMedium"
            csize: 15
            cweight: Font.Medium
            text: root.data ? root.data.desc : ""
        }

        Tx {
            theme: root.theme
            role: "bodySmall"
            csize: 12
            text: root.data ? "Feels " + root.data.feels + "\u00B0  \u00B7  " + root.data.hum + "%  \u00B7  " + root.data.wind : ""
            color: root.theme.subtext
        }

        Item {
            width: 1
            height: 6
        }

        Rectangle {
            visible: !root.md3
            width: parent.width
            height: 1
            color: root.theme.border
        }

        Item {
            width: 1
            height: 4
        }

        Row {
            width: parent.width

            Repeater {
                model: root.data ? root.data.days : []

                Item {
                    required property var modelData

                    width: parent.width / 3
                    height: 38

                    MdShape {
                        visible: root.md3
                        kind: "rounded"
                        radius: root.theme.shape.md
                        color: root.theme.tonal

                        anchors {
                            fill: parent
                            leftMargin: 3
                            rightMargin: 3
                        }

                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.md3 ? (parent.height - height) / 2 : 0

                        Tx {
                            theme: root.theme
                            anchors.horizontalCenter: parent.horizontalCenter
                            role: "labelMedium"
                            csize: 12
                            cweight: Font.DemiBold
                            text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
                            color: root.md3 ? root.theme.tonalFg : root.theme.accent
                        }

                        Row {
                            spacing: 6

                            Tx {
                                theme: root.theme
                                role: "bodySmall"
                                csize: 13
                                text: modelData.hi + "\u00B0"
                                color: root.md3 ? root.theme.tonalFg : root.theme.text
                            }

                            Tx {
                                theme: root.theme
                                role: "bodySmall"
                                csize: 13
                                text: modelData.lo + "\u00B0"
                                color: root.md3 ? root.theme.tonalFg : root.theme.subtext
                                opacity: root.md3 ? 0.7 : 1
                            }

                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }

        }

    }

}
