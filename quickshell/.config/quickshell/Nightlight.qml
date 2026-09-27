import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Nightlight: warm/cool via hyprsunset. Toggle + temperature slider.
Scope {
  id: scope
  property bool open: false
  property bool on: false
  property int temp: 3500
  property int anchorX: 10
  property int anchorY: 0

  FileView {
    id: stateFile
    path: Quickshell.env("HOME") + "/.cache/nightlight.json"
    watchChanges: true
    onFileChanged: stateFile.reload()
  }
  function loadState() {
    try {
      const d = JSON.parse(stateFile.text());
      scope.on = !!d.on;
      if (d.temp) scope.temp = d.temp;
    } catch (e) { /* defaults */ }
  }
  function saveState() {
    stateFile.setText(JSON.stringify({ on: scope.on, temp: scope.temp }));
  }
  Component.onCompleted: { loadState(); apply(); }
  function apply() {
    applyTimer.restart();
  }
  Timer {
    id: applyTimer
    interval: 250
    onTriggered: {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/scripts/utility/nightlight.sh", scope.on ? "on" : "off", String(scope.temp)]);
    }
  }

  IpcHandler {
    target: "nightlight"
    function toggle(): void { scope.open = !scope.open; if (scope.open) loadState(); }
    function open(): void { scope.open = true; }
    function openAt(x: int, y: int): void { scope.anchorX = x; scope.anchorY = y; scope.open = true; loadState(); }
    function close(): void { scope.open = false; }
    function on(): void { scope.on = true; scope.saveState(); scope.apply(); }
    function off(): void { scope.on = false; scope.saveState(); scope.apply(); }
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true }
      margins { top: scope.anchorY; left: scope.anchorX }
      exclusiveZone: 0
      color: "transparent"
      implicitWidth: 280
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
          else if (event.key === Qt.Key_Space) { scope.on = !scope.on; scope.saveState(); scope.apply(); }
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            const delta = event.key === Qt.Key_Left || event.key === Qt.Key_H ? -250 : 250;
            scope.temp = Math.max(1000, Math.min(6500, scope.temp + delta));
            scope.saveState(); scope.apply();
          } else if (event.key === Qt.Key_J) { scope.on = false; scope.saveState(); scope.apply(); }
          else if (event.key === Qt.Key_K) { scope.on = true; scope.saveState(); scope.apply(); }
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.border
        ColumnLayout {
          id: col
          anchors { fill: parent; margins: 9 }
          spacing: 10
          RowLayout {
            Layout.fillWidth: true
            Text { text: "󰌵 Nightlight"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
            Rectangle {
              implicitWidth: 52
              implicitHeight: 24
              color: scope.on ? Theme.accent : Theme.bgAlt
              border.color: Theme.border
              Text {
                anchors.centerIn: parent
                text: scope.on ? "on" : "off"
                color: scope.on ? Theme.bg : Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { scope.on = !scope.on; scope.saveState(); scope.apply(); }
              }
            }
          }
          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            opacity: scope.on ? 1.0 : 0.4
            Text { text: scope.temp + "K"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; Layout.preferredWidth: 48 }
            Item {
              id: track
              Layout.fillWidth: true
              implicitHeight: 22
              Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 6
                color: Theme.bgAlt
                Rectangle {
                  anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                  width: parent.width * ((scope.temp - 1000) / 5500)
                  color: Theme.accent
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function set(e) {
                  scope.temp = Math.round(1000 + Math.max(0, Math.min(1, e.x / track.width)) * 5500);
                  scope.saveState(); scope.apply();
                }
                onPressed: e => set(e)
                onPositionChanged: e => { if (pressed) set(e); }
              }
            }
          }
        }
      }
    }
  }
}
