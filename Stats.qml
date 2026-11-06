import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: ({
    })
    property var options: ({
    })
    property real cpu: 0
    property real mem: 0
    property real disk: 0
    property real temp: 0
    property string memText: "-"
    property string diskText: "-"
    property var prev: null
    readonly property bool imp: options.units === "imperial"
    readonly property bool md3: theme.md3 === true
    readonly property bool fluid: true

    function gb(kb) {
        return (kb / 1.04858e+06).toFixed(1) + " GB";
    }

    function parse(t) {
        var L = t.trim().split("\n");
        if (L.length < 3)
            return ;

        var f = L[0].trim().split(/\s+/).slice(1).map(Number);
        var idle = f[3] + (f[4] || 0), total = 0;
        for (var i = 0; i < Math.min(8, f.length); i++) total += f[i]
        if (prev) {
            var dt = total - prev.t, di = idle - prev.i;
            if (dt > 0)
                cpu = 1 - di / dt;

        }
        prev = {
            "t": total,
            "i": idle
        };
        var m = L[1].trim().split(/\s+/).map(Number);
        mem = 1 - m[1] / m[0];
        memText = gb(m[0] - m[1]) + " / " + gb(m[0]);
        var d = L[2].trim().split(/\s+/).map(Number);
        disk = d[0] / d[1];
        diskText = gb(d[0]) + " / " + gb(d[1]);
        temp = L.length > 3 ? Number(L[3]) / 1000 : 0;
    }

    implicitWidth: 260
    implicitHeight: 4 * 38

    Process {
        id: proc

        command: ["sh", "-c", "head -1 /proc/stat; awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t, a}' /proc/meminfo; df -P / | awk 'NR==2{print $3, $2}'; cat /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -n | tail -1"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4

        Stat {
            th: root.theme
            label: "CPU"
            value: root.cpu
            valueText: Math.round(root.cpu * 100) + "%"
            col: root.theme.blue
        }

        Stat {
            th: root.theme
            label: "Memory"
            value: root.mem
            valueText: root.memText
            col: root.theme.purple
        }

        Stat {
            th: root.theme
            label: "Disk  /"
            value: root.disk
            valueText: root.diskText
            col: root.theme.green
        }

        Stat {
            th: root.theme
            label: "Temperature"
            value: root.temp / 100
            valueText: root.temp > 0 ? Math.round(root.imp ? root.temp * 9 / 5 + 32 : root.temp) + (root.imp ? "\u00B0F" : "\u00B0C") : "n/a"
            col: root.temp > 80 ? root.theme.red : (root.temp > 65 ? root.theme.yellow : root.theme.peach)
        }

    }

    component Stat: Item {
        property var th
        property string label
        property real value
        property string valueText
        property color col
        readonly property bool m3: th !== undefined && th.md3 === true

        width: parent ? parent.width : 260
        height: 34

        Tx {
            theme: th
            role: "labelMedium"
            csize: 12
            cweight: Font.Medium
            text: label
            color: th.subtext
        }

        Tx {
            theme: th
            role: "labelMedium"
            csize: 12
            anchors.right: parent.right
            text: valueText
        }

        Rectangle {
            y: m3 ? 19 : 21
            width: parent.width
            height: m3 ? 10 : 7
            radius: height / 2
            color: m3 ? th.tonal : th.surface

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, value))
                height: parent.height
                radius: height / 2
                color: col

                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }

                }

                Behavior on width {
                    NumberAnimation {
                        duration: m3 ? 450 : 350
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
