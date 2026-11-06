import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  Variants {
    model: Config.ids
    delegate: WidgetWindow {
      required property string modelData
      wid: modelData
    }
  }
  EditOverlay {}

  IpcHandler {
    target: "rosewidgets"
    function toggleEdit(): void { Config.editMode = !Config.editMode; }
    function setEdit(on: bool): void { Config.editMode = on; }
    function setStyle(s: string): void { Config.setStyle(s); }
    function reload(): void { Quickshell.reload(false); }
  }
}
