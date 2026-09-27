import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Clipboard history (cliphist) on SUPER+V. Type to filter, enter to copy, esc closes.
Scope {
  id: scope
  property bool open: false
  property var entries: []
  property string filterText: ""
  property int selIndex: 0
  property var filtered: {
    const q = scope.filterText.toLowerCase();
    const list = scope.entries.filter(e => e.toLowerCase().includes(q));
    if (scope.selIndex >= list.length) scope.selIndex = Math.max(0, list.length - 1);
    return list;
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  function reload() {
    scope.filterText = "";
    scope.selIndex = 0;
    clipProc.running = true;
  }

  Process {
    id: clipProc
    command: ["bash", "-lc", "cliphist list 2>/dev/null | head -n 50"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const ln of this.text.split("\n")) {
          if (ln.trim() !== "") out.push(ln);
        }
        scope.entries = out;
        scope.selIndex = 0;
      }
    }
  }

  function copyEntry(line) {
    if (!line) return;
    Quickshell.execDetached(["bash", "-lc", "printf %s " + "'" + line.replace(/'/g, "'\\''") + "'" + " | cliphist decode | wl-copy"]);
    scope.open = false;
  }

  function moveSel(d) {
    scope.selIndex = Math.max(0, Math.min(scope.filtered.length - 1, scope.selIndex + d));
  }

  function activateSel() {
    copyEntry(scope.filtered[scope.selIndex]);
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#a0000000"
      exclusiveZone: 0

      HyprlandFocusGrab {
        windows: [win]
        active: scope.open
        onCleared: scope.open = false
      }

      MouseArea {
        anchors.fill: parent
        onClicked: scope.open = false
      }

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: 520
        implicitHeight: 380
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
          anchors { fill: parent; margins: 12 }
          spacing: 8
          RowLayout {
            Layout.fillWidth: true
            Text { text: "Clipboard"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
            Text {
              text: "wipe"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["bash", "-lc", "cliphist wipe"]); scope.entries = []; }
              }
            }
          }
          TextInput {
            id: query
            Layout.fillWidth: true
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            focus: true
            onTextChanged: { scope.filterText = text; scope.selIndex = 0; }
            onAccepted: scope.activateSel()
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_Tab) historyList.forceActiveFocus();
              else if (event.key === Qt.Key_Down) scope.moveSel(1);
              else if (event.key === Qt.Key_Up) scope.moveSel(-1);
            }
            Rectangle {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -6 }
              height: 1
              color: Theme.border
            }
          }
          ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            focus: true
            model: scope.filtered
            currentIndex: scope.selIndex
            onCurrentIndexChanged: scope.selIndex = currentIndex
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: parent.width
              implicitHeight: 30
              color: index === scope.selIndex ? Theme.bgAlt : "transparent"
              Text {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                verticalAlignment: Text.AlignVCenter
                text: modelData.replace(/^\d+\t/, "")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { scope.selIndex = index; scope.copyEntry(modelData); }
              }
            }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) scope.moveSel(1);
              else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) scope.moveSel(-1);
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) scope.activateSel();
            }
          }
        }
      }
      Component.onCompleted: { scope.reload(); query.forceActiveFocus(); }
    }
  }
}
