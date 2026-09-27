import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: scope
  property bool open: false
  property var bindings: []

  function describeChord(chord) {
    const c = chord.toUpperCase();
    const known = {
      "SUPER + RETURN": "Open terminal",
      "SUPER + SHIFT + RETURN": "Open floating terminal",
      "SUPER + Q": "Close focused window",
      "SUPER + E": "Open file manager",
      "SUPER + B": "Open web browser",
      "SUPER + SPACE": "Open app launcher",
      "SUPER + SHIFT + E": "Open power menu",
      "SUPER + CTRL + K": "Show keyboard shortcuts",
      "SUPER + CTRL + W": "Choose wallpaper",
      "SUPER + CTRL + T": "Choose color theme",
      "SUPER + CTRL + F": "Open tmux project sessionizer",
      "SUPER + N": "Dismiss notifications",
      "CTRL + ALT + L": "Lock screen",
      "SUPER + F": "Toggle floating window",
      "SUPER + H": "Focus left window",
      "SUPER + J": "Focus lower window",
      "SUPER + K": "Focus upper window",
      "SUPER + L": "Focus right window",
      "SUPER + SHIFT + L": "Switch layout",
      "SUPER + M": "Toggle fullscreen",
      "SUPER + S": "Toggle notes scratchpad",
      "SUPER + SHIFT + S": "Move window to scratch workspace",
      "SUPER + V": "Open clipboard history",
      "SUPER + PERIOD": "Open emoji picker",
      "SUPER + P": "Next wallpaper",
      "SUPER + CTRL + B": "Open system monitor",
      "SUPER + SHIFT + M": "Open media controls",
      "SUPER + CTRL + R": "Open reminders",
      "SUPER + CTRL + ALT + R": "Open reminders",
      "SUPER + CTRL + SHIFT + R": "Clear reminders",
      "SUPER + CTRL + I": "Apply desktop preset",
      "SUPER + LEFT": "Focus left window",
      "SUPER + RIGHT": "Focus right window",
      "SUPER + UP": "Focus upper window",
      "SUPER + DOWN": "Focus lower window",
      "SUPER + SHIFT + LEFT": "Move window left",
      "SUPER + SHIFT + RIGHT": "Move window right",
      "SUPER + SHIFT + UP": "Move window up",
      "SUPER + SHIFT + DOWN": "Move window down",
      "SUPER + CTRL + H": "Previous workspace",
      "SUPER + CTRL + L": "Next workspace",
      "PRINT": "Screenshot active display",
      "SUPER + PRINT": "Screenshot window",
      "SUPER + SHIFT + PRINT": "Screenshot selected area",
      "XF86AUDIOPLAY": "Play or pause media",
      "XF86AUDIOPAUSE": "Play or pause media",
      "XF86AUDIONEXT": "Next media track",
      "XF86AUDIOPREV": "Previous media track",
      "XF86AUDIOMUTE": "Mute or unmute audio",
      "XF86AUDIORAISEVOLUME": "Raise audio volume",
      "XF86AUDIOLOWERVOLUME": "Lower audio volume",
      "XF86AUDIOMICMUTE": "Mute or unmute microphone",
      "XF86MONBRIGHTNESSUP": "Raise screen brightness",
      "XF86MONBRIGHTNESSDOWN": "Lower screen brightness"
    };
    if (known[c]) return known[c];
    const ws = c.match(/^SUPER( \+ SHIFT)? \+ ([0-9])$/);
    if (ws) return ws[1] ? "Move window to workspace " + (ws[2] === "0" ? 10 : ws[2]) : "Switch to workspace " + (ws[2] === "0" ? 10 : ws[2]);
    if (c.startsWith("SUPER + SHIFT + ARROW")) return "Move window to another direction";
    if (c.startsWith("SUPER + ARROW")) return "Focus window in another direction";
    if (c.includes("MOUSE")) return "Move or resize window with mouse";
    return "Custom shortcut";
  }

  IpcHandler {
    target: "keybindings"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  Process {
    id: readBinds
    command: ["hyprctl", "-j", "binds"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { scope.bindings = JSON.parse(this.text).map(b => {
          const mask = Number(b.modmask ?? 0);
          const mods = [];
          if (mask & 64) mods.push("SUPER");
          if (mask & 4) mods.push("CTRL");
          if (mask & 8) mods.push("ALT");
          if (mask & 1) mods.push("SHIFT");
          let key = b.key || b.keycode || (b.mouse ? "Mouse" : "Key");
          key = String(key).replace(/^\s+|\s+$/g, "").toUpperCase();
          const chord = mods.concat([key]).join(" + ");
          return { chord, action: b.description || scope.describeChord(chord) };
        }).sort((a, b) => a.chord.localeCompare(b.chord)); }
        catch (e) { scope.bindings = []; console.warn("Could not read Hyprland keybindings: " + e); }
      }
    }
  }
  onOpenChanged: if (open) readBinds.running = true

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#99000000"
      exclusiveZone: 0
      HyprlandFocusGrab { windows: [win]; active: scope.open; onCleared: scope.open = false }
      MouseArea { anchors.fill: parent; onClicked: scope.open = false }

      Rectangle {
        anchors.centerIn: parent
        width: Math.min(380, parent.width - 36)
        height: Math.min(520, parent.height - 36)
        color: Theme.bg
        border.color: Theme.border
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 10
          Text { text: "Keyboard shortcuts"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
          TextInput {
            id: query
            Layout.fillWidth: true
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
            focus: true
            onTextChanged: list.currentIndex = 0
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_Tab) list.forceActiveFocus();
              else if ((event.key === Qt.Key_J || event.key === Qt.Key_Down) && (event.modifiers & Qt.ControlModifier)) list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
              else if ((event.key === Qt.Key_K || event.key === Qt.Key_Up) && (event.modifiers & Qt.ControlModifier)) list.currentIndex = Math.max(0, list.currentIndex - 1);
            }
            Rectangle {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
              height: 1
              color: Theme.border
            }
          }
          ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 2; focus: true
            model: ScriptModel {
              values: {
                const q = query.text.toLowerCase().trim();
                if (!q) return scope.bindings;
                return scope.bindings.filter(b => (b.chord + " " + b.action).toLowerCase().includes(q));
              }
            }
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: list.width; height: 36
              color: list.currentIndex === index ? Theme.bgAlt : "transparent"
              RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                Text { Layout.preferredWidth: 200; text: modelData.chord; color: Theme.accent; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: modelData.action; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight }
              }
            }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) scope.open = false;
              else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
              else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) list.currentIndex = Math.max(0, list.currentIndex - 1);
            }
          }
          HelpToggle { hint: "Search actions or keys · Tab to shortcuts · j/k move · Esc close" }
        }
        Component.onCompleted: query.forceActiveFocus()
      }
    }
  }
}
