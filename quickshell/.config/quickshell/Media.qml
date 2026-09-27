import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Widgets

// Media widget: vim-driven player control. j/k player, space play, n/b next/prev,
// h/l seek, s shuffle, r loop, R raise, +/- volume, q/esc close.
Scope {
  id: scope
  property bool open: false
  property int selIndex: 0
  property bool showKeys: false
  property bool scrubbing: false
  property real scrubPos: 0

  IpcHandler {
    target: "media"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  property var players: [...(Mpris.players.values ?? [])]
  property var player: {
    if (!players.length) return null;
    if (scope.selIndex >= players.length) scope.selIndex = 0;
    return players[scope.selIndex];
  }

  function fmt(sec) {
    sec = Math.max(0, Math.floor(sec ?? 0));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m + ":" + (s < 10 ? "0" + s : s);
  }

  Timer {
    interval: 1000
    repeat: true
    running: scope.open && (scope.player?.playbackState === MprisPlaybackState.Playing)
    onTriggered: scope.player?.positionChanged()
  }

  function cycleLoop() {
    const p = scope.player;
    if (!p || !p.loopSupported) return;
    if (p.loopState === MprisLoopState.None) p.loopState = MprisLoopState.Track;
    else if (p.loopState === MprisLoopState.Track) p.loopState = MprisLoopState.Playlist;
    else p.loopState = MprisLoopState.None;
  }

  function loopLabel() {
    const p = scope.player;
    if (!p || !p.loopSupported) return "";
    if (p.loopState === MprisLoopState.Track) return "repeat-one";
    if (p.loopState === MprisLoopState.Playlist) return "repeat-all";
    return "no-repeat";
  }

  function press(fn) {
    const p = scope.player;
    if (!p) return;
    if (fn === "toggle") p.togglePlaying();
    else if (fn === "next") p.next();
    else if (fn === "prev") p.previous();
    else if (fn === "shuffle") { if (p.shuffleSupported) p.shuffle = !p.shuffle; }
    else if (fn === "loop") cycleLoop();
  }

  function handleKey(event) {
    const k = event.key;
    if (k === Qt.Key_Escape || k === Qt.Key_Q) { scope.open = false; return; }
    if (k === Qt.Key_J) {
      if (scope.players.length > 1) scope.selIndex = (scope.selIndex + 1) % scope.players.length;
      return;
    }
    if (k === Qt.Key_K) {
      if (scope.players.length > 1) scope.selIndex = (scope.selIndex - 1 + scope.players.length) % scope.players.length;
      return;
    }
    if (k === Qt.Key_H) { if (scope.player?.canSeek) scope.player.seek(-10); return; }
    if (k === Qt.Key_L) { if (scope.player?.canSeek) scope.player.seek(10); return; }
    if (k === Qt.Key_Space) { scope.press("toggle"); return; }
    if (k === Qt.Key_N) { scope.press("next"); return; }
    if (k === Qt.Key_B) { scope.press("prev"); return; }
    if (k === Qt.Key_S) {
      const p = scope.player;
      if (p && p.shuffleSupported) p.shuffle = !p.shuffle;
      return;
    }
    if (k === Qt.Key_R) {
      if (event.modifiers & Qt.ShiftModifier) { if (scope.player?.canRaise) scope.player.raise(); }
      else scope.cycleLoop();
      return;
    }
    if (k === Qt.Key_Plus || k === Qt.Key_Equal) {
      const p = scope.player;
      if (p && p.volumeSupported) p.volume = Math.min(1, p.volume + 0.05);
      return;
    }
    if (k === Qt.Key_Minus || k === Qt.Key_Underscore) {
      const p = scope.player;
      if (p && p.volumeSupported) p.volume = Math.max(0, p.volume - 0.05);
      return;
    }
    if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (scope.player?.canRaise) scope.player.raise(); return; }
  }

  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      // no anchors: floating, compositor centers on the active monitor
      color: "transparent"
      implicitWidth: 460
      implicitHeight: col.implicitHeight + 24
      exclusiveZone: 0

      HyprlandFocusGrab {
        windows: [win]
        active: scope.open
        onCleared: scope.open = false
      }

      // keyboard focus lives here (PanelWindow itself can't take Keys)
      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => scope.handleKey(event)
      }

      Rectangle {
        anchors.centerIn: parent
        width: 460
        height: col.implicitHeight + 24
        color: Theme.bg
        border.color: Theme.border

        MouseArea {
          anchors.fill: parent
          onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
          id: col
          anchors { fill: parent; margins: 12 }
          spacing: 8

          // ---- player switcher ----
          RowLayout {
            visible: scope.players.length > 1
            Layout.fillWidth: true
            spacing: 4
            Repeater {
              model: scope.players
              Rectangle {
                required property var modelData
                required property int index
                implicitWidth: tabTxt.implicitWidth + 20
                implicitHeight: 24
                color: index === scope.selIndex ? Theme.accent : "transparent"
                border.color: index === scope.selIndex ? Theme.accent : Theme.border
                Text {
                  id: tabTxt
                  anchors.centerIn: parent
                  text: modelData.identity || ("player " + (index + 1))
                  color: index === scope.selIndex ? Theme.bg : Theme.dim
                  font.family: Theme.font
                  font.pixelSize: 11
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: scope.selIndex = index
                }
              }
            }
          }

          Text {
            visible: !scope.player
            text: "nothing playing"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
          }

          RowLayout {
            visible: !!scope.player
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
              implicitWidth: 88
              implicitHeight: 88
              color: Theme.bgAlt
              border.color: Theme.border
              Image {
                anchors.fill: parent
                anchors.margins: 2
                visible: (scope.player?.trackArtUrl ?? "") !== ""
                source: scope.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
              }
              Text {
                anchors.centerIn: parent
                visible: (scope.player?.trackArtUrl ?? "") === ""
                text: "♪"
                color: Theme.dim
                font.pixelSize: 32
              }
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2
              Text {
                Layout.fillWidth: true
                text: scope.player?.trackTitle || "Unknown Title"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
              }
              Text {
                Layout.fillWidth: true
                text: (scope.player?.trackArtist || "Unknown Artist") + (scope.player?.trackAlbum ? "  ·  " + scope.player.trackAlbum : "")
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11
                elide: Text.ElideRight
              }
              Text {
                text: (scope.player?.identity ?? "") + (scope.player?.shuffle ? "  ·  shuffle" : "") + (scope.loopLabel() !== "" ? "  ·  " + scope.loopLabel() : "")
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }

          // ---- position ----
          RowLayout {
            visible: !!scope.player
            Layout.fillWidth: true
            spacing: 8
            Text { text: scope.fmt(scope.player?.position); color: Theme.dim; font.family: Theme.font; font.pixelSize: 11; Layout.preferredWidth: 40 }
            Item {
              id: posTrack
              Layout.fillWidth: true
              implicitHeight: 20
              Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 5
                color: Theme.bgAlt
                Rectangle {
                  anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                  width: {
                    if (scope.scrubbing) return parent.width * scope.scrubPos;
                    const p = scope.player;
                    if (!p || !(p.length > 0)) return 0;
                    return parent.width * Math.min(1, p.position / p.length);
                  }
                  color: Theme.accent
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function jump(e) {
                  const p = scope.player;
                  if (!p || !p.canSeek || !(p.length > 0)) return;
                  scope.scrubPos = Math.max(0, Math.min(1, e.x / posTrack.width));
                  p.position = Math.max(0, Math.min(p.length, p.length * scope.scrubPos));
                }
                onPressed: e => { scope.scrubbing = true; jump(e); }
                onReleased: scope.scrubbing = false
                onCanceled: scope.scrubbing = false
                onPositionChanged: e => { if (pressed) jump(e); }
              }
            }
            Text { text: (scope.player && scope.player.length > 0) ? scope.fmt(scope.player.length) : "--:--"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
          }

          // ---- transport ----
          RowLayout {
            visible: !!scope.player
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Repeater {
              model: [
                { icon: "media-playlist-shuffle", hint: "shuffle", fn: "shuffle" },
                { icon: "media-skip-backward", hint: "prev", fn: "prev" },
                { icon: (scope.player?.isPlaying ?? false) ? "media-playback-pause" : "media-playback-start", hint: "play", fn: "toggle", big: true },
                { icon: "media-skip-forward", hint: "next", fn: "next" },
                { icon: "media-playlist-repeat", hint: "loop", fn: "loop" }
              ]
              ColumnLayout {
                required property var modelData
                spacing: 1
                Rectangle {
                  implicitWidth: modelData.big ? 52 : 44
                  implicitHeight: 36
                  color: Theme.bgAlt
                  border.color: Theme.border
                  IconImage { anchors.centerIn: parent; source: Quickshell.iconPath(modelData.icon); implicitSize: 20 }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: scope.press(modelData.fn)
                  }
                }
              }
            }
          }

          HelpToggle {
            hint: "j/k player · h/l seek · Space play/pause · n/b track · Esc close"
            expanded: scope.showKeys
            onExpandedChanged: scope.showKeys = expanded
          }
        }
      }
    }
  }
}
