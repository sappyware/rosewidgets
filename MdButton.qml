import QtQuick

Item {
    id: b

    property var th
    property string shape: "squircle"
    property string pressedShape: "circle"
    property color bg: "gray"
    property color fg: "white"
    property string label: ""
    property string icon: ""
    property real glyphSize: 20
    property real iconSize: 26
    readonly property bool down: ma.pressed
    readonly property bool hovered: ma.containsMouse

    signal clicked()

    scale: down ? 0.93 : (hovered ? 1.04 : 1)
    onLabelChanged: pop.restart()
    onIconChanged: pop.restart()

    MdShape {
        anchors.fill: parent
        kind: b.down ? b.pressedShape : b.shape
        color: b.bg
    }

    MdShape {
        anchors.fill: parent
        kind: b.down ? b.pressedShape : b.shape
        color: Qt.alpha(b.fg, b.down ? 0.14 : (b.hovered ? 0.08 : 0))
    }

    Item {
        id: glyphBox

        anchors.centerIn: parent
        width: 1
        height: 1

        Text {
            visible: b.icon === ""
            anchors.centerIn: parent
            text: b.label
            color: b.fg
            font.pixelSize: b.glyphSize
        }

        Icon {
            visible: b.icon !== ""
            anchors.centerIn: parent
            width: b.iconSize
            height: b.iconSize
            kind: b.icon
            color: b.fg
        }

    }

    SequentialAnimation {
        id: pop

        NumberAnimation {
            target: glyphBox
            property: "scale"
            to: 0.6
            duration: 70
        }

        NumberAnimation {
            target: glyphBox
            property: "scale"
            to: 1
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 2.5
        }

    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
        onClicked: b.clicked()
    }

    Behavior on scale {
        SpringAnimation {
            spring: 5
            damping: 0.3
            epsilon: 0.002
        }

    }

    Behavior on width {
        SpringAnimation {
            spring: 5
            damping: 0.35
            epsilon: 0.5
        }

    }

}
