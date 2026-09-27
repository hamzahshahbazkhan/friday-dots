import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Reminders: countdown list + centered quickshell alerts (no notification daemon).
// SUPER+CTRL+R open, SUPER+CTRL+ALT+R open, SUPER+CTRL+SHIFT+R clear.
Scope {
  id: scope
  property bool open: false
  property var items: [] // {id, epoch, msg}
  property string alertId: ""
  property string alertMsg: ""

  readonly property string helper: Quickshell.env("HOME") + "/.config/scripts/remind/reminders.sh"
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/reminders"

  IpcHandler {
    target: "reminder"
    function toggle(): void { scope.open = !scope.open; if (scope.open) refresh(); }
    function open(): void { scope.open = true; refresh(); }
    function close(): void { scope.open = false; }
    function clear(): void { scope.run(helper + " clear"); scope.items = []; }
    function fire(id: string): void {
      msgProc.targetId = id;
      msgProc.running = true;
    }
  }

  function run(cmd) {
    Quickshell.execDetached(["bash", "-lc", cmd]);
    Qt.callLater(() => refresh());
  }

  function refresh() { listProc.running = true; }

  function remaining(epoch) {
    const s = Math.max(0, epoch - Math.floor(Date.now() / 1000));
    if (s < 90) return "in " + s + "s";
    const m = Math.floor(s / 60);
    if (m < 90) return "in " + m + "m";
    return "in " + Math.floor(m / 60) + "h" + (m % 60 ? (m % 60) + "m" : "");
  }

  Timer {
    interval: 20000
    repeat: true
    running: scope.open
    onTriggered: refresh()
  }

  Timer {
    id: alertTimer
    interval: 120000
    onTriggered: { scope.alertId = ""; scope.alertMsg = ""; }
  }

  Process {
    id: listProc
    command: [scope.helper, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const ln of this.text.trim().split("\n")) {
          const p = ln.split("|");
          if (p.length < 3 || !p[0]) continue;
          out.push({ id: p[0], epoch: parseInt(p[1]) || 0, msg: p.slice(2).join("|") });
        }
        out.sort((a, b) => a.epoch - b.epoch);
        scope.items = out;
      }
    }
  }

  Process {
    id: msgProc
    property string targetId: ""
    command: [scope.helper, "msg", targetId]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = this.text.trim();
        if (m !== "") {
          scope.alertId = msgProc.targetId;
          scope.alertMsg = m;
          alertTimer.restart();
        }
        Quickshell.execDetached(["rm", "-f", scope.stateDir + "/" + msgProc.targetId]);
        refresh();
      }
    }
  }

  function schedule() {
    const mins = minsInput.text.trim();
    const msg = msgInput.text.trim();
    if (!/^[0-9]+$/.test(mins) || msg === "") return;
    Quickshell.execDetached(["bash", "-lc", scope.helper + " schedule " + mins + " '" + msg.replace(/'/g, "") + "'"]);
    minsInput.text = "";
    msgInput.text = "";
    const t = Qt.createQmlObject("import QtQuick; Timer { interval: 800; repeat: false; running: true }", scope);
    t.triggered.connect(() => { refresh(); t.destroy(); });
  }

  function dismissAlert() {
    scope.alertId = "";
    scope.alertMsg = "";
    alertTimer.stop();
  }

  // ================= panel =================
  LazyLoader {
    active: scope.open
    PanelWindow {
      id: win
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#a0000000"
      exclusiveZone: 0

      HyprlandFocusGrab {
        windows: [win]
        active: scope.open && scope.alertMsg === ""
        onCleared: scope.open = false
      }

      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => { if (event.key === Qt.Key_Escape) scope.open = false; }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: scope.open = false
      }

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: 440
        implicitHeight: col.implicitHeight + 24
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        MouseArea {
          anchors.fill: parent
          onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
          id: col
          anchors { fill: parent; margins: 12 }
          spacing: 8

          Text { text: "New reminder"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextInput {
              id: minsInput
              Layout.preferredWidth: 60
              color: Theme.fg
              font.family: Theme.font
              font.pixelSize: 13
              validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }
              onAccepted: msgInput.forceActiveFocus()
              Keys.onPressed: event => { if (event.key === Qt.Key_Escape) scope.open = false; }
              Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -4 }
                height: 1; color: Theme.border
              }
            }
            Text { text: "min"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
            TextInput {
              id: msgInput
              Layout.fillWidth: true
              color: Theme.fg
              font.family: Theme.font
              font.pixelSize: 13
              onAccepted: scope.schedule()
              Keys.onPressed: event => { if (event.key === Qt.Key_Escape) scope.open = false; }
              Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -4 }
                height: 1; color: Theme.border
              }
            }
            Rectangle {
              implicitWidth: 64
              implicitHeight: 28
              color: Theme.accent
              Text { anchors.centerIn: parent; text: "Set"; color: Theme.bg; font.family: Theme.font; font.pixelSize: 12 }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: scope.schedule()
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Text { text: "Pending"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Text {
              visible: scope.items.length > 0
              text: "clear all"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { scope.run(scope.helper + " clear"); scope.items = []; }
              }
            }
          }
          Repeater {
            model: scope.items
            Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: 30
              color: "transparent"
              RowLayout {
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                spacing: 8
                Text {
                  Layout.fillWidth: true
                  text: modelData.msg
                  color: Theme.fg; font.family: Theme.font; font.pixelSize: 12
                  elide: Text.ElideRight
                }
                Text {
                  text: scope.remaining(modelData.epoch)
                  color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
                }
                Text {
                  text: "×"; color: Theme.dim; font.pixelSize: 14
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached(["bash", "-lc", "systemctl --user stop reminder-" + parent.modelData.id + " 2>/dev/null; rm -f '" + scope.stateDir + "/" + parent.modelData.id + "'"]);
                      Qt.callLater(() => refresh());
                    }
                  }
                }
              }
            }
          }
          Text {
            visible: scope.items.length === 0
            text: "none pending — e.g. 7 min, take the chai off"
            color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
          }
        }
      }
      Component.onCompleted: minsInput.forceActiveFocus()
    }
  }

  // ================= centered alert =================
  LazyLoader {
    active: scope.alertMsg !== ""
    PanelWindow {
      id: alertWin
      anchors { top: true; left: true; right: true; bottom: true }
      color: "#a0000000"
      exclusiveZone: 0

      HyprlandFocusGrab {
        windows: [alertWin]
        active: scope.alertMsg !== ""
        onCleared: dismissAlert()
      }

      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Space) dismissAlert();
        }
      }

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: 400
        implicitHeight: alertCol.implicitHeight + 28
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        ColumnLayout {
          id: alertCol
          anchors { fill: parent; margins: 14 }
          spacing: 10
          Text { text: "REMINDER"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter }
          Text {
            text: scope.alertMsg
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 15
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
          }
          Rectangle {
            implicitWidth: 120
            implicitHeight: 32
            Layout.alignment: Qt.AlignHCenter
            color: Theme.accent
            Text { anchors.centerIn: parent; text: "Done"; color: Theme.bg; font.family: Theme.font; font.pixelSize: 12 }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: dismissAlert()
            }
          }
        }
      }
    }
  }
}
