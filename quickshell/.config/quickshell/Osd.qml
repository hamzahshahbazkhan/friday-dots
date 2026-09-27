import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets

// Volume / brightness OSD, bottom-center. Replaces wob.
Scope {
  id: root
  property bool showVol: false
  property bool showBright: false
  property real bright: 0

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  // Watch volume/mute via properties (Connections target is null until
  // Pipewire populates the default sink, which logs warnings).
  property real vol: Pipewire.defaultAudioSink?.audio.volume ?? -1
  property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false
  property bool primed: false
  onVolChanged: if (primed && vol >= 0) { root.showVol = true; hideTimer.restart(); }
  onMutedChanged: if (primed) { root.showVol = true; hideTimer.restart(); }
  Timer { interval: 2000; running: true; repeat: false; onTriggered: root.primed = true }

  Timer {
    id: hideTimer
    interval: 1200
    onTriggered: { root.showVol = false; root.showBright = false; }
  }

  // brightness poller listens via hyprland binds calling: quickshell ipc call osd brightness <0-100>
  IpcHandler {
    target: "osd"
    function showVolume(): void { root.showVol = true; hideTimer.restart(); }
    function brightness(v: real): void { root.bright = v; root.showBright = true; hideTimer.restart(); }
  }

  LazyLoader {
    active: root.showVol || root.showBright
    PanelWindow {
      anchors.bottom: true
      margins.bottom: screen.height / 5
      exclusiveZone: 0
      mask: Region {}
      implicitWidth: 400
      implicitHeight: 48
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.border
        RowLayout {
          anchors { fill: parent; leftMargin: 12; rightMargin: 16 }
          spacing: 10
          IconImage {
            visible: !root.showBright
            implicitSize: 22
            source: {
              const s = Pipewire.defaultAudioSink?.audio;
              if (!s) return Quickshell.iconPath("audio-volume-muted");
              if (s.muted || s.volume === 0) return Quickshell.iconPath("audio-volume-muted");
              if (s.volume < 0.33) return Quickshell.iconPath("audio-volume-low");
              if (s.volume < 0.66) return Quickshell.iconPath("audio-volume-medium");
              return Quickshell.iconPath("audio-volume-high");
            }
          }
          Text {
            visible: root.showBright
            text: "☀"
            color: Theme.accent
            font.pixelSize: 20
          }
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 8
            radius: 0
            color: Theme.bgAlt
            Rectangle {
              anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
              implicitWidth: {
                if (root.showBright) return parent.width * Math.max(0, Math.min(1, root.bright / 100));
                const s = Pipewire.defaultAudioSink?.audio;
                return parent.width * (s ? Math.max(0, Math.min(1, s.volume)) : 0);
              }
              radius: parent.radius
              color: Theme.accent
            }
          }
          Text {
            text: {
              if (root.showBright) return Math.round(root.bright) + "%";
              const s = Pipewire.defaultAudioSink?.audio;
              if (!s) return "--";
              if (s.muted) return "mute";
              return Math.round(s.volume * 100) + "%";
            }
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 12
          }
        }
      }
    }
  }
}
