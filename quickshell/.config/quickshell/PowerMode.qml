import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: scope
  property bool open: false
  property string current: "balanced"
  readonly property var modes: [
    { id: "power-saver", label: "Saver", detail: "Lower power use and heat" },
    { id: "balanced", label: "Balanced", detail: "Everyday performance" },
    { id: "performance", label: "Performance", detail: "Maximum responsiveness" }
  ]
  IpcHandler {
    target: "power"
    function toggle(): void { scope.open = !scope.open; if (scope.open) readProc.running = true; }
    function open(): void { scope.open = true; readProc.running = true; }
    function close(): void { scope.open = false; }
  }
  Process {
    id: readProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector { onStreamFinished: { const mode = this.text.trim(); if (mode) scope.current = mode; } }
  }
  function choose(mode) {
    Quickshell.execDetached(["powerprofilesctl", "set", mode]);
    scope.current = mode;
    scope.open = false;
  }
  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; right: true }
      margins { top: 0; right: 10 }
      exclusiveZone: 0; color: "transparent"
      implicitWidth: 220; implicitHeight: panel.implicitHeight + 18
      HyprlandFocusGrab { windows: [win]; active: scope.open; onCleared: scope.open = false }
      Rectangle {
        anchors.fill: parent; color: Theme.bg; border.color: Theme.border
        ColumnLayout {
          id: panel
          anchors.fill: parent; anchors.margins: 12; spacing: 9
          Text { text: "Power mode"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
          Repeater {
            model: scope.modes
            Rectangle {
              id: modeRow
              required property var modelData
              required property int index
              Layout.fillWidth: true; implicitHeight: 48
              color: scope.current === modelData.id ? Theme.bgAlt : "transparent"
              border.color: scope.current === modelData.id ? Theme.accent : Theme.border
              RowLayout {
                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9
                ColumnLayout {
                  Layout.fillWidth: true; spacing: 1
                  Text { text: modeRow.modelData.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12 }
                  Text { text: modeRow.modelData.detail; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 }
                }
                //Text { text: scope.current === parent.parent.modelData.id ? "✓" : ""; color: Theme.accent; font.pixelSize: 13 }
              }
              MouseArea { anchors.fill: parent; onClicked: scope.choose(modelData.id) }
            }
          }
          Item {
            id: keyboardNav
            Layout.fillWidth: true; implicitHeight: 1; focus: true
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) scope.current = scope.modes[(scope.modes.findIndex(m => m.id === scope.current) + 1) % scope.modes.length].id;
              else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) scope.current = scope.modes[(scope.modes.findIndex(m => m.id === scope.current) + scope.modes.length - 1) % scope.modes.length].id;
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) scope.choose(scope.current);
            }
          }
          HelpToggle { hint: "j/k select · Enter apply · Esc close" }
        }
        Component.onCompleted: keyboardNav.forceActiveFocus()
      }
    }
  }
}
