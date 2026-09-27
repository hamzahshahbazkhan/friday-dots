import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Bluetooth panel backed by bluetoothctl: radio, scan, connect/disconnect.
Scope {
  id: scope
  property bool open: false
  property var devices: []
  property bool powered: true
  property bool scanning: false
  property int focusIndex: 0

  IpcHandler {
    target: "bluetooth"
    function toggle(): void { scope.open = !scope.open; if (scope.open) refresh(); }
    function open(): void { scope.open = true; refresh(); }
    function close(): void { scope.open = false; }
  }

  function refresh() {
    powerProc.running = true;
    listProc.running = true;
  }

  Process {
    id: powerProc
    command: ["bash", "-lc", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]
    stdout: StdioCollector { onStreamFinished: scope.powered = (this.text.trim() === "on") }
  }
  Process {
    id: listProc
    command: ["bash", "-lc", "for l in $(bluetoothctl devices 2>/dev/null | awk '{print $2}'); do n=$(bluetoothctl devices 2>/dev/null | grep \"$l\" | cut -d' ' -f3-); c=$(bluetoothctl info \"$l\" 2>/dev/null | grep -q 'Connected: yes' && echo 1 || echo 0); echo \"$l|$n|$c\"; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const ln of this.text.trim().split("\n")) {
          const p = ln.split("|");
          if (p.length < 2 || !p[0]) continue;
          out.push({ mac: p[0], name: p[1] || p[0], connected: p[2] === "1" });
        }
        out.sort((a, b) => (b.connected - a.connected));
        scope.devices = out;
        scope.focusIndex = out.length ? Math.min(scope.focusIndex, out.length - 1) : 0;
      }
    }
  }
  Process {
    id: scanProc
    command: ["bash", "-lc", "bluetoothctl --timeout 8 scan on 2>&1 | head -n1"]
    stdout: StdioCollector { onStreamFinished: { scope.scanning = false; listProc.running = true; } }
  }
  function run(cmd) { Quickshell.execDetached(["bash", "-lc", cmd]); }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; right: true }
      margins { top: 0; right: 10 }
      exclusiveZone: 0
      color: "transparent"
      implicitWidth: 320
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
          else if ((event.key === Qt.Key_J || event.key === Qt.Key_Down) && scope.devices.length) scope.focusIndex = Math.min(scope.devices.length - 1, scope.focusIndex + 1);
          else if ((event.key === Qt.Key_K || event.key === Qt.Key_Up) && scope.devices.length) scope.focusIndex = Math.max(0, scope.focusIndex - 1);
          else if (event.key === Qt.Key_H) { scope.run("bluetoothctl power off"); scope.powered = false; }
          else if (event.key === Qt.Key_L) { scope.run("bluetoothctl power on"); scope.powered = true; }
          else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && scope.devices[scope.focusIndex]) {
            const d = scope.devices[scope.focusIndex];
            scope.run(d.connected ? "bluetoothctl disconnect " + d.mac : "bluetoothctl connect " + d.mac);
            Qt.callLater(() => { const t = Qt.createQmlObject("import QtQuick; Timer { interval: 1500; repeat: false; running: true }", scope); t.triggered.connect(() => { refresh(); t.destroy(); }); });
          }
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
            Text { text: "Bluetooth"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
            Text {
              text: scope.scanning ? "scanning…" : "scan"
              color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { if (!scope.scanning) { scope.scanning = true; scanProc.running = true; } }
              }
            }
            Rectangle {
              implicitWidth: 52; implicitHeight: 24
              color: scope.powered ? Theme.accent : Theme.bgAlt
              border.color: Theme.border
              Text {
                anchors.centerIn: parent
                text: scope.powered ? "on" : "off"
                color: scope.powered ? Theme.bg : Theme.muted
                font.family: Theme.font; font.pixelSize: 11
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  scope.run(scope.powered ? "bluetoothctl power off" : "bluetoothctl power on");
                  Qt.callLater(() => refresh());
                }
              }
            }
          }
          Repeater {
            model: scope.devices
            Rectangle {
              required property var modelData
              required property int index
              Layout.fillWidth: true
              implicitHeight: 28
              color: modelData.connected || scope.focusIndex === index ? Theme.bgAlt : "transparent"
              border.color: scope.focusIndex === index ? Theme.accent : (modelData.connected ? Theme.border : "transparent")
              RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 8
                Text { text: parent.modelData.connected ? "●" : "○"; color: Theme.accent; font.pixelSize: 10 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: parent.parent.modelData.name; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight }
                  Text { text: parent.parent.modelData.mac; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 }
                }
                Text {
                  text: parent.modelData.connected ? "disconnect" : "connect"
                  color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
                }
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  scope.focusIndex = parent.index;
                  const d = parent.modelData;
                  scope.run(d.connected ? "bluetoothctl disconnect " + d.mac : "bluetoothctl connect " + d.mac);
                  Qt.callLater(() => { const t = Qt.createQmlObject("import QtQuick; Timer { interval: 1500; repeat: false; running: true }", scope); t.triggered.connect(() => { refresh(); t.destroy(); }); });
                }
              }
            }
          }
          Text {
            visible: scope.devices.length === 0
            text: scope.powered ? "no devices — scan?" : "bluetooth is off"
            color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
          }
        }
      }
    }
  }
}
