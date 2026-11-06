import QtQuick

Text {
    id: t

    property var theme: ({
    })
    property string role: "bodyMedium"
    property real csize: 13
    property int cweight: Font.Normal
    property real cls: 0
    property bool emph: false
    readonly property var ty: theme && theme.md3 === true && theme.type ? theme.type[role] : null

    font.family: theme.font
    font.pixelSize: ty ? ty.size : csize
    font.weight: ty ? (emph ? Font.DemiBold : ty.weight) : cweight
    font.letterSpacing: ty ? ty.ls : cls
    color: theme.text
}
