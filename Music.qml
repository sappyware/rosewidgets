import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property var theme: ({
    })
    property var options: ({
    })
    readonly property bool md3: theme.md3 === true
    readonly property var player: {
        var l = Mpris.players.values;
        for (var i = 0; i < l.length; i++) if (l[i].isPlaying) {
            return l[i];
        }
        return l.length > 0 ? l[0] : null;
    }
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string artKind: md3 ? (playing ? (options.art_shape || "cookie") : (options.art_shape_paused || "squircle")) : "rounded"
    readonly property real len: player && player.lengthSupported ? player.length : 0
    readonly property real pos: player && player.positionSupported ? player.position : 0
    readonly property real frac: len > 0 ? Math.min(1, pos / len) : 0
    readonly property bool fluid: true

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    function seekTo(f) {
        if (player && player.canSeek && len > 0)
            player.position = f * len;

    }

    implicitWidth: 340
    implicitHeight: md3 ? 124 : 112

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Item {
        id: art

        width: 96
        height: 96
        anchors.verticalCenter: parent.verticalCenter

        MdShape {
            anchors.fill: parent
            kind: root.artKind
            radius: 14
            color: root.md3 ? root.theme.tonal : root.theme.surface

            Text {
                anchors.centerIn: parent
                text: "♪"
                font.pixelSize: 38
                color: root.md3 ? root.theme.tonalFg : root.theme.subtext
            }

        }

        Image {
            id: img

            anchors.fill: parent
            visible: false
            asynchronous: true
            sourceSize.width: 200
            sourceSize.height: 200
            fillMode: Image.PreserveAspectCrop
            source: root.player ? root.player.trackArtUrl : ""
        }

        Item {
            id: mask

            anchors.fill: parent
            visible: false
            layer.enabled: true

            MdShape {
                anchors.fill: parent
                kind: root.artKind
                radius: 14
                color: "black"
            }

        }

        MultiEffect {
            anchors.fill: parent
            opacity: img.status === Image.Ready ? 1 : 0
            visible: opacity > 0.01
            source: img
            maskEnabled: true
            maskSource: mask

            Behavior on opacity {
                NumberAnimation {
                    duration: 350
                }

            }

        }

    }

    Column {
        spacing: 2

        anchors {
            left: art.right
            leftMargin: 16
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        Tx {
            theme: root.theme
            width: parent.width
            elide: Text.ElideRight
            role: "titleMedium"
            csize: 16
            cweight: Font.DemiBold
            text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
        }

        Tx {
            theme: root.theme
            width: parent.width
            elide: Text.ElideRight
            role: "bodyMedium"
            csize: 13
            text: root.player ? (root.player.trackArtist || "") : ""
            color: root.theme.subtext
        }

        Item {
            width: 1
            height: root.md3 ? 2 : 6
        }

        Item {
            visible: !root.md3
            width: parent.width
            height: 14

            Rectangle {
                y: 5
                width: parent.width
                height: 4
                radius: 2
                color: root.theme.surface

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: root.theme.accent
                    width: parent.width * root.frac
                }

            }

            MouseArea {
                anchors.fill: parent
                onClicked: (m) => {
                    return root.seekTo(m.x / width);
                }
            }

        }

        Item {
            visible: !root.md3
            width: parent.width
            height: 12

            Tx {
                theme: root.theme
                role: "labelSmall"
                csize: 10
                text: root.fmt(root.pos)
                color: root.theme.subtext
            }

            Tx {
                theme: root.theme
                role: "labelSmall"
                csize: 10
                anchors.right: parent.right
                text: root.fmt(root.len)
                color: root.theme.subtext
            }

        }

        Row {
            visible: !root.md3
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 26

            Btn {
                fg: root.theme.text
                icon: "prev"
                onClicked: {
                    if (root.player) {
                        root.player.previous();
                    }
                }
            }

            Btn {
                fg: root.theme.text
                icon: root.playing ? "pause" : "play"
                onClicked: {
                    if (root.player) {
                        root.player.togglePlaying();
                    }
                }
            }

            Btn {
                fg: root.theme.text
                icon: "next"
                onClicked: {
                    if (root.player) {
                        root.player.next();
                    }
                }
            }

        }

        Item {
            visible: root.md3
            width: parent.width
            height: 18

            Tx {
                id: tL

                theme: root.theme
                role: "labelSmall"
                csize: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.pos)
                color: root.theme.subtext
            }

            Tx {
                id: tR

                theme: root.theme
                role: "labelSmall"
                csize: 10
                text: root.fmt(root.len)
                color: root.theme.subtext

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

            }

            WavyProgress {
                value: root.frac
                playing: root.playing
                wavy: root.options.wavy !== false
                activeColor: root.theme.accent
                trackColor: root.theme.tonal
                onSeek: (f) => {
                    return root.seekTo(f);
                }

                anchors {
                    left: tL.right
                    leftMargin: 8
                    right: tR.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }

            }

        }

        Item {
            visible: root.md3
            width: 1
            height: 2
        }

        Row {
            visible: root.md3
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            height: 46

            MdButton {
                id: bPrev

                th: root.theme
                height: 46
                width: 52 + (down ? 8 : 0) - (bPlay.down ? 4 : 0)
                shape: "squircle"
                pressedShape: "circle"
                bg: root.theme.tonal
                fg: root.theme.tonalFg
                icon: "prev"
                onClicked: {
                    if (root.player) {
                        root.player.previous();
                    }
                }
            }

            MdButton {
                id: bPlay

                th: root.theme
                height: 46
                width: 88 + (down ? 10 : 0) - ((bPrev.down || bNext.down) ? 4 : 0)
                shape: root.playing ? "squircle" : "circle"
                pressedShape: root.playing ? "circle" : "squircle"
                bg: root.theme.accent
                fg: root.theme.accent_fg
                iconSize: 28
                icon: root.playing ? "pause" : "play"
                onClicked: {
                    if (root.player) {
                        root.player.togglePlaying();
                    }
                }
            }

            MdButton {
                id: bNext

                th: root.theme
                height: 46
                width: 52 + (down ? 8 : 0) - (bPlay.down ? 4 : 0)
                shape: "squircle"
                pressedShape: "circle"
                bg: root.theme.tonal
                fg: root.theme.tonalFg
                icon: "next"
                onClicked: {
                    if (root.player) {
                        root.player.next();
                    }
                }
            }

        }

    }

    component Btn: Item {
        id: bt

        property color fg: "white"
        property string icon: "play"

        signal clicked()

        width: 26
        height: 26
        opacity: ma.pressed ? 0.5 : 1
        scale: ma.pressed ? 0.85 : 1

        Icon {
            anchors.centerIn: parent
            width: 24
            height: 24
            kind: bt.icon
            color: bt.fg
        }

        MouseArea {
            id: ma

            anchors.fill: parent
            anchors.margins: -8
            onClicked: bt.clicked()
        }

        Behavior on scale {
            SpringAnimation {
                spring: 5
                damping: 0.3
                epsilon: 0.002
            }

        }

    }

}
