import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Month calendar popup for the bar clock.
Scope {
  id: scope
  property bool open: false
  property int year: 0
  property int month: 0 // 0-11
  property int selectedDay: 1

  function reset() {
    const d = new Date();
    scope.year = d.getFullYear();
    scope.month = d.getMonth();
    scope.selectedDay = d.getDate();
  }
  function moveDay(amount) {
    const d = new Date(scope.year, scope.month, scope.selectedDay + amount);
    scope.year = d.getFullYear();
    scope.month = d.getMonth();
    scope.selectedDay = d.getDate();
  }
  Component.onCompleted: reset()

  IpcHandler {
    target: "calendar"
    function toggle(): void { if (!scope.open) reset(); scope.open = !scope.open; }
    function open(): void { reset(); scope.open = true; }
    function close(): void { scope.open = false; }
  }

  readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]
  // Monday-first grid of {day, inMonth, today}
  property var cells: {
    const first = new Date(scope.year, scope.month, 1);
    const startCol = (first.getDay() + 6) % 7;
    const daysIn = new Date(scope.year, scope.month + 1, 0).getDate();
    const daysPrev = new Date(scope.year, scope.month, 0).getDate();
    const now = new Date();
    const out = [];
    for (let i = 0; i < 42; i++) {
      const dnum = i - startCol + 1;
      if (dnum < 1) out.push({ day: daysPrev + dnum, inMonth: false, today: false });
      else if (dnum > daysIn) out.push({ day: dnum - daysIn, inMonth: false, today: false });
      else out.push({ day: dnum, inMonth: true,
        today: scope.year === now.getFullYear() && scope.month === now.getMonth() && dnum === now.getDate() });
    }
    return out;
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true }
      margins { top: 0 }
      exclusiveZone: 0
      color: "transparent"
      implicitWidth: 264
      implicitHeight: col.implicitHeight + 20

      HyprlandFocusGrab {
        windows: [win]
        active: scope.open
        onCleared: scope.open = false
      }

      // keyboard focus lives here (PanelWindow itself can't take Keys)
      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) scope.open = false;
          else if (event.key === Qt.Key_T) reset();
          else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) moveDay(7);
          else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) moveDay(-7);
          else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) moveDay(-1);
          else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) moveDay(1);
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.border
        ColumnLayout {
          id: col
          anchors { fill: parent; margins: 9 }
          spacing: 8
          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "‹"; color: Theme.dim; font.pixelSize: 16
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                if (scope.month === 0) { scope.month = 11; scope.year--; } else scope.month--;
              } }
            }
            Text {
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: scope.monthNames[scope.month] + " " + scope.year
              color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true
            }
            Text {
              text: "Today"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: reset() }
            }
            Text {
              text: "›"; color: Theme.dim; font.pixelSize: 16
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                if (scope.month === 11) { scope.month = 0; scope.year++; } else scope.month++;
              } }
            }
          }
          GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 2
            Repeater {
              model: ["M","T","W","T","F","S","S"]
              Text {
                required property var modelData
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignHCenter
                text: modelData; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10
              }
            }
            Repeater {
              model: scope.cells
              Rectangle {
                required property var modelData
                Layout.preferredWidth: 32
                Layout.preferredHeight: 23
                property bool selected: modelData.inMonth && modelData.day === scope.selectedDay
                color: selected ? Theme.accent : "transparent"
                border.color: modelData.today && !selected ? Theme.accent : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: modelData.day
                  color: parent.selected ? Theme.bg : (modelData.inMonth ? Theme.fg : Theme.dim)
                  opacity: (!modelData.inMonth && !modelData.today) ? 0.4 : 1.0
                  font.family: Theme.font
                  font.pixelSize: 11
                }
                MouseArea { anchors.fill: parent; onClicked: { scope.selectedDay = modelData.day; if (!modelData.inMonth) { const d = new Date(scope.year, scope.month + (modelData.day > 20 ? -1 : 1), modelData.day); scope.year = d.getFullYear(); scope.month = d.getMonth(); } } }
              }
            }
          }
        }
      }
    }
  }
}
