import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: scope
  property bool open: false
  property int currentIndex: 0

  IpcHandler {
    target: "powermenu"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  function run(cmd) {
    Quickshell.execDetached(["bash", "-lc", cmd]);
    scope.open = false;
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#80000000"
      exclusiveZone: 0
      HyprlandFocusGrab {
        windows: [win]
        active: scope.open
        onCleared: scope.open = false
      }

      // Keyboard focus lives on the window content, not PanelWindow itself.
      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) scope.open = false;
          else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) scope.currentIndex = Math.min(4, scope.currentIndex + 1);
          else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) scope.currentIndex = Math.max(0, scope.currentIndex - 1);
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const actions = ["loginctl lock-session", "hyprctl dispatch exit", "systemctl suspend", "systemctl reboot", "systemctl poweroff"];
            scope.run(actions[scope.currentIndex]);
          }
        }
      }
      MouseArea { anchors.fill: parent; onClicked: scope.open = false }

      Rectangle {
        anchors.centerIn: parent
        width: Math.min(650, parent.width - 40)
        height: 174
        color: Theme.bg
        border.color: Theme.border
        ColumnLayout {
          anchors { fill: parent; margins: 14 }
          spacing: 12
          Text { text: "Power"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
              model: [
                { label: "Lock", icon: "󰌾", cmd: "loginctl lock-session" },
                { label: "Log out", icon: "󰗽", cmd: "hyprctl dispatch exit" },
                { label: "Suspend", icon: "󰒲", cmd: "systemctl suspend" },
                { label: "Restart", icon: "󰜉", cmd: "systemctl reboot" },
                { label: "Shut down", icon: "󰐥", cmd: "systemctl poweroff" }
              ]
              Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 88
                color: scope.currentIndex === index ? Theme.bgAlt : Theme.bg
                border.color: scope.currentIndex === index ? Theme.accent : Theme.border
                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4
                  Text { Layout.alignment: Qt.AlignHCenter; text: parent.parent.modelData.icon; font.pixelSize: 24; color: Theme.fg }
                  Text { Layout.alignment: Qt.AlignHCenter; text: parent.parent.modelData.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11 }
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: scope.currentIndex = index
                  onClicked: scope.run(parent.modelData.cmd)
                }
              }
            }
          }
          HelpToggle { hint: "h/l select · Enter apply · Esc close" }
        }
      }
    }
  }
}
