import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: scope
  property bool open: false
  property int index: 0
  property var themes: []

  IpcHandler {
    target: "themes"
    function toggle(): void { scope.open = !scope.open; if (scope.open) load(); }
    function open(): void { scope.open = true; load(); }
    function close(): void { scope.open = false; }
  }

  function load() { themeProc.running = true; }
  function move(step) {
    if (scope.themes.length) scope.index = (scope.index + step + scope.themes.length) % scope.themes.length;
  }
  function apply(theme) {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/scripts/themes/set-theme.sh", theme]);
    scope.open = false;
  }

  Process {
    id: themeProc
    command: ["bash", "-lc", "for f in ~/.config/themes/*/quickshell.json; do [ -f \"$f\" ] || continue; n=${f%/quickshell.json}; n=${n##*/}; [ \"$n\" = current ] && continue; printf '%s\\t' \"$n\"; python -c 'import json,sys; d=json.load(open(sys.argv[1])); print(\"\\t\".join(d.get(k,\"#000000\") for k in (\"background\",\"backgroundAlt\",\"foreground\",\"accent\",\"urgent\")))' \"$f\"; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        scope.themes = this.text.trim().split("\n").filter(Boolean).map(line => {
          const p = line.split("\t");
          return { name: p[0], colors: p.slice(1) };
        });
        scope.index = Math.min(scope.index, scope.themes.length - 1);
      }
    }
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
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) if (scope.themes.length) scope.apply(scope.themes[scope.index].name);
        }
      }
      Rectangle {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 32); height: Math.min(340, parent.height - 32)
        color: Theme.bg; border.color: Theme.border
        ColumnLayout {
          anchors.fill: parent; anchors.margins: 14; spacing: 8
          Text { text: "Themes"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter }
          ListView {
            id: carousel
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            model: scope.themes
            currentIndex: scope.index
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: height / 2 - 78
            preferredHighlightEnd: preferredHighlightBegin
            highlightMoveDuration: 140
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: carousel.width; height: 156
              color: Theme.bgAlt; border.color: index === scope.index ? Theme.accent : Theme.border
              opacity: index === scope.index ? 1 : 0.55
              ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                Text { text: modelData.name; color: Theme.fg; font.family: Theme.font; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
                RowLayout {
                  Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8
                  Repeater {
                    model: modelData.colors
                    Rectangle { required property string modelData; Layout.fillWidth: true; Layout.fillHeight: true; color: modelData }
                  }
                }
              }
              MouseArea { anchors.fill: parent; onClicked: { scope.index = index; scope.apply(modelData.name); } }
            }
          }
          HelpToggle { hint: "j/k browse · Enter apply · Esc close" }
        }
      }
    }
  }
}
