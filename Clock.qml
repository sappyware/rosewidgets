import QtQuick
import Quickshell

Item {
    id: root

    property var theme: ({
    })
    property var options: ({
    })
    readonly property bool h24: options.hour24 === true
    readonly property bool sec: options.show_seconds === true
    readonly property bool showDate: options.show_date !== false

    implicitWidth: Math.max(220, col.implicitWidth)
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clk

        precision: root.sec ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: col

        spacing: 0

        Tx {
            theme: root.theme
            visible: root.showDate
            role: "labelLarge"
            csize: 13
            cweight: Font.DemiBold
            cls: 1
            text: Qt.formatDate(clk.date, "dddd").toUpperCase()
            color: root.theme.accent
        }

        Tx {
            theme: root.theme
            role: "displayLarge"
            csize: 58
            cweight: Font.Light
            textFormat: Text.RichText
            text: {
                var t = Qt.formatDateTime(clk.date, (root.h24 ? "HH:mm" : "h:mm") + (root.sec ? ":ss" : ""));
                return root.h24 ? t : t + "<span style='font-size:22px'> " + Qt.formatDateTime(clk.date, "AP") + "</span>";
            }
        }

        Tx {
            theme: root.theme
            visible: root.showDate
            role: "bodyLarge"
            csize: 14
            text: Qt.formatDate(clk.date, "d MMMM yyyy")
            color: root.theme.subtext
        }

    }

}
