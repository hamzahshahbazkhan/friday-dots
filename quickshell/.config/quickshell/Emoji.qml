import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Emoji picker on SUPER+. — click to copy, esc closes.
Scope {
  id: scope
  property bool open: false
  property string filterText: ""

  IpcHandler {
    target: "emoji"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "emoji-toggle"
    description: "Toggle emoji picker"
    onPressed: scope.open = !scope.open
  }

  property var all: ["😄","😂","😍","✌️","❤️","👍","👎","🤞","🤘","😘","🙄","😉","🙏","🤤","💰","🎉","💯","🥂","👌","👋","💪","🤯","🔥","✨","🎯","🚀","👀","💡","📌","📎","✅","❌","⚠️","➡️","⬅️","⬆️","⬇️","©️","®️","™️","—","–","…","°","×","÷","≠","≈","∞","✓","○","●","■","□","▲","△","⚫","⚪","🔴","🟢","🔵","🟡","🏠","📁","📝","📷","🎵","🎬","📞","✉️","🔍","🔒","🔑","⚙️","💻","🐧","⌨️","🖱️","🔋","📶","🎧","☀️","🌙","⭐","🌈","☕","🍕"]

  property var filtered: {
    const q = scope.filterText.toLowerCase().trim();
    if (!q) return scope.all;
    const names = { smile: "😄", cry: "😂", love: "😍", heart: "❤️", fire: "🔥", rocket: "🚀", check: "✅", cross: "❌", warn: "⚠️", arrow: "➡️", star: "⭐", moon: "🌙", sun: "☀️", coffee: "☕", lock: "🔒", search: "🔍" };
    return scope.all.filter(e => e.includes(q) || Object.keys(names).some(k => k.includes(q) && names[k] === e));
  }

  function pick(e) {
    Quickshell.execDetached(["bash", "-lc", "printf %s '" + e + "' | wl-copy"]);
    scope.open = false;
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
        implicitWidth: 420
        implicitHeight: 320
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
          anchors { fill: parent; margins: 12 }
          spacing: 8
          TextInput {
            id: query
            Layout.fillWidth: true
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            focus: true
            onTextChanged: scope.filterText = text
            onAccepted: { if (scope.filtered.length > 0) scope.pick(scope.filtered[emojiGrid.currentIndex] ?? scope.filtered[0]); }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_Tab) emojiGrid.forceActiveFocus();
            }
            Rectangle {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -6 }
              height: 1
              color: Theme.border
            }
          }
          GridView {
            id: emojiGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            cellWidth: 44
            cellHeight: 44
            model: scope.filtered
            onModelChanged: currentIndex = 0
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: 44; height: 44
              color: emojiGrid.currentIndex === index ? Theme.bgAlt : "transparent"
              Text {
                anchors.centerIn: parent
                text: modelData
                color: Theme.fg
                font.pixelSize: 22
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: scope.pick(parent.modelData)
                onEntered: emojiGrid.currentIndex = index
              }
            }
            Keys.onPressed: event => {
              const cols = Math.max(1, Math.floor(emojiGrid.width / emojiGrid.cellWidth));
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) emojiGrid.currentIndex = Math.min(emojiGrid.count - 1, emojiGrid.currentIndex + cols);
              else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) emojiGrid.currentIndex = Math.max(0, emojiGrid.currentIndex - cols);
              else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) emojiGrid.currentIndex = Math.max(0, emojiGrid.currentIndex - 1);
              else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) emojiGrid.currentIndex = Math.min(emojiGrid.count - 1, emojiGrid.currentIndex + 1);
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) scope.pick(scope.filtered[emojiGrid.currentIndex]);
            }
          }
        }
      }
      Component.onCompleted: query.forceActiveFocus()
    }
  }
}
