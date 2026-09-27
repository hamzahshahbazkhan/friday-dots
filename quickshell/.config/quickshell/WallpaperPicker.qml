import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: scope
  property bool open: false
  property int index: 0
  property var wallpapers: []

  IpcHandler {
    target: "wallpapers"
    function toggle(): void { scope.open = !scope.open; if (scope.open) load(); }
    function open(): void { scope.open = true; load(); }
    function close(): void { scope.open = false; }
  }

  function load() { wallpaperProc.running = true; }
  function move(step) {
    if (scope.wallpapers.length) scope.index = (scope.index + step + scope.wallpapers.length) % scope.wallpapers.length;
  }
  function apply(path) {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/scripts/wallpaper/hyprpaper.sh", "--set", path]);
    scope.open = false;
  }

  Process {
    id: wallpaperProc
    command: ["bash", "-lc", "find -L ~/.config/.wallpapers -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print 2>/dev/null | sort -V"]
    stdout: StdioCollector { onStreamFinished: { scope.wallpapers = this.text.trim().split("\n").filter(Boolean); scope.index = Math.min(scope.index, scope.wallpapers.length - 1); } }
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#99000000"; exclusiveZone: 0
      HyprlandFocusGrab { windows: [win]; active: scope.open; onCleared: scope.open = false }
      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) scope.open = false;
          else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) scope.move(1);
          else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) scope.move(-1);
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) if (scope.wallpapers.length) scope.apply(scope.wallpapers[scope.index]);
        }
      }
      Rectangle {
        anchors.centerIn: parent
        width: Math.min(620, parent.width - 32); height: Math.min(400, parent.height - 32)
        color: Theme.bg; border.color: Theme.border
        ColumnLayout {
          anchors.fill: parent; anchors.margins: 14; spacing: 8
          Text { text: "Wallpapers"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter }
          ListView {
            id: carousel
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            model: scope.wallpapers
            currentIndex: scope.index
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: height / 2 - 110
            preferredHighlightEnd: preferredHighlightBegin
            highlightMoveDuration: 140
            delegate: Rectangle {
              required property string modelData
              required property int index
              width: carousel.width; height: 220
              color: Theme.bgAlt; border.color: index === scope.index ? Theme.accent : Theme.border
              opacity: index === scope.index ? 1 : 0.55
              Image {
                anchors.fill: parent; anchors.margins: 6
                source: "file://" + modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
              }
              Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 32; color: "#cc000000"
                Text {
                  anchors.centerIn: parent
                  text: modelData.split("/").pop()
                  color: "white"; font.family: Theme.font; font.pixelSize: 10
                  elide: Text.ElideMiddle
                  width: parent.width - 20
                  horizontalAlignment: Text.AlignHCenter
                }
              }
              MouseArea { anchors.fill: parent; onClicked: { scope.index = index; scope.apply(modelData); } }
            }
          }
          HelpToggle { hint: "j/k browse · Enter apply · Esc close" }
        }
      }
    }
  }
}
