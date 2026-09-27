import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

// Master volume + output picker + per-app mixer (Omarchy audio panel).
Scope {
  id: scope
  property bool open: false
  property int sinkIndex: 0

  IpcHandler {
    target: "audio"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  // ---- outputs via pactl ----
  property var sinks: []
  property string defaultSink: ""
  Process {
    id: sinkProc
    command: ["bash", "-lc", "echo \"DEF $(pactl get-default-sink 2>/dev/null)\"; pactl --format=json list sinks 2>/dev/null | python3 -c 'import json,sys; [print(s[\"name\"]+\"\\t\"+s.get(\"description\",\"\")) for s in json.load(sys.stdin)]'"]
    running: scope.open
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n");
        const out = [];
        for (const ln of lines) {
          if (ln.startsWith("DEF ")) scope.defaultSink = ln.slice(4).trim();
          else if (ln.includes("\t")) {
            const p = ln.split("\t");
            out.push({ name: p[0], desc: p[1] ?? p[0] });
          }
        }
        scope.sinks = out;
        scope.sinkIndex = out.length ? Math.min(scope.sinkIndex, out.length - 1) : 0;
      }
    }
  }
  function useSink(name) {
    Quickshell.execDetached(["bash", "-lc", "pactl set-default-sink '" + name + "'; for i in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input $i '" + name + "'; done"]);
    sinkProc.running = true;
  }

  component VolSlider: Item {
    id: slider
    property real value: 0
    signal scrubbed(real v)
    implicitHeight: 22
    Rectangle {
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
      height: 6
      color: Theme.bgAlt
      Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * Math.max(0, Math.min(1, slider.value))
        color: Theme.accent
      }
      Rectangle {
        x: parent.width * Math.max(0, Math.min(1, slider.value)) - 6
        anchors.verticalCenter: parent.verticalCenter
        width: 12; height: 12
        color: Theme.fg
      }
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      function set(e) { slider.scrubbed(Math.max(0, Math.min(1, e.x / slider.width))); }
      onPressed: e => set(e)
      onPositionChanged: e => { if (pressed) set(e); }
    }
  }

  component AppRow: ColumnLayout {
    required property var node
    PwObjectTracker { objects: [node] }
    spacing: 2
    RowLayout {
      Layout.fillWidth: true
      Text {
        Layout.fillWidth: true
        text: node.properties["application.name"] ?? node.description ?? node.name
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 12
        elide: Text.ElideRight
      }
      Text {
        text: Math.round((node.audio?.volume ?? 0) * 100) + "%"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 11
      }
      Text {
        text: (node.audio?.muted ?? false) ? "󰝟" : "󰕾"
        color: Theme.dim
        font.pixelSize: 12
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: node.audio.muted = !node.audio.muted
        }
      }
    }
    VolSlider {
      Layout.fillWidth: true
      value: node.audio?.volume ?? 0
      onScrubbed: v => { node.audio.volume = v; if (node.audio.muted && v > 0) node.audio.muted = false; }
    }
  }

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
          else if ((event.key === Qt.Key_J || event.key === Qt.Key_Down) && scope.sinks.length) scope.sinkIndex = Math.min(scope.sinks.length - 1, scope.sinkIndex + 1);
          else if ((event.key === Qt.Key_K || event.key === Qt.Key_Up) && scope.sinks.length) scope.sinkIndex = Math.max(0, scope.sinkIndex - 1);
          else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && scope.sinks[scope.sinkIndex]) scope.useSink(scope.sinks[scope.sinkIndex].name);
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_H || event.key === Qt.Key_L) {
            const s = Pipewire.defaultAudioSink?.audio;
            if (s) s.volume = Math.max(0, Math.min(1, s.volume + (event.key === Qt.Key_Right || event.key === Qt.Key_L ? 0.05 : -0.05)));
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
          spacing: 6

          Text { text: "Audio"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }

          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
              text: {
                const s = Pipewire.defaultAudioSink?.audio;
                if (!s) return "󰝟";
                if (s.muted) return "󰝟";
                return "󰕾";
              }
              color: Theme.accent
              font.pixelSize: 18
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { const s = Pipewire.defaultAudioSink?.audio; if (s) s.muted = !s.muted; }
              }
            }
            VolSlider {
              Layout.fillWidth: true
              value: Pipewire.defaultAudioSink?.audio.volume ?? 0
              onScrubbed: v => {
                const s = Pipewire.defaultAudioSink?.audio;
                if (!s) return;
                s.volume = v;
                if (s.muted && v > 0) s.muted = false;
              }
            }
            Text {
              text: {
                const s = Pipewire.defaultAudioSink?.audio;
                if (!s) return "--";
                if (s.muted) return "muted";
                return Math.round(s.volume * 100) + "%";
              }
              color: Theme.fg
              font.family: Theme.font
              font.pixelSize: 12
              Layout.preferredWidth: 48
            }
          }

          Text { text: "Output"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
          Repeater {
            model: scope.sinks
            Rectangle {
              required property var modelData
              required property int index
              Layout.fillWidth: true
              implicitHeight: 30
              color: modelData.name === scope.defaultSink || scope.sinkIndex === index ? Theme.bgAlt : "transparent"
              border.color: scope.sinkIndex === index ? Theme.accent : (modelData.name === scope.defaultSink ? Theme.border : "transparent")
              Text {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                verticalAlignment: Text.AlignVCenter
                text: (modelData.name === scope.defaultSink ? "● " : "○ ") + modelData.desc
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { scope.sinkIndex = parent.index; scope.useSink(parent.modelData.name); }
              }
            }
          }

          Text { text: "Apps"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11; visible: linkTracker.linkGroups.length > 0 }
          PwNodeLinkTracker {
            id: linkTracker
            node: Pipewire.defaultAudioSink
          }
          Repeater {
            model: linkTracker.linkGroups
            AppRow {
              required property var modelData
              Layout.fillWidth: true
              node: modelData.source
            }
          }
        }
      }
    }
  }
}
