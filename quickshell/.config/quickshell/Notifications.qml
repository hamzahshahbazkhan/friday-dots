import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Io

Scope {
  id: scope
  property list<var> popups: []
  property string batteryAlert: ""

  NotificationServer {
    id: server
    // Keep notifications visible long enough to read.
    onNotification: notif => {
      notif.tracked = true;
      scope.popups.push(notif);
      // auto-expire
      Qt.callLater(() => dismissLater(notif));
    }
  }

  Timer {
    interval: 30000; running: true; repeat: true
    onTriggered: {
      const d = UPower.displayDevice;
      if (!d || d.isLaptopBattery === false) return;
      const pct = Math.round((d.percentage ?? 0) * 100);
      const charging = d.state === UPowerDeviceState.Charging || d.state === UPowerDeviceState.FullyCharged;
      let level = charging ? "" : (pct <= 10 ? "critical" : (pct <= 20 ? "low" : ""));
      if (!level) { scope.batteryAlert = ""; return; }
      if (scope.batteryAlert === level) return;
      scope.batteryAlert = level;
      const urgency = level === "critical" ? "critical" : "normal";
      const summary = level === "critical" ? "Battery critically low" : "Battery low";
      Quickshell.execDetached(["notify-send", "--app-name=System", "--urgency=" + urgency, "--expire-time=5000", summary, "Battery is at " + pct + "%. Connect a charger."]);
    }
  }

  function dismissLater(n) {
    const ms = (n.urgency === NotificationUrgency.Critical) ? 12000 : 8000;
    const t = Qt.createQmlObject('import QtQuick; Timer { interval: ' + ms + '; repeat: false; running: true }', scope);
    t.triggered.connect(() => {
      const i = scope.popups.indexOf(n);
      try { n.dismiss(); } catch (e) {}
      if (i >= 0) scope.popups.splice(i, 1);
      scope.popupsChanged();
      t.destroy();
    });
  }

  IpcHandler {
    target: "notifications"
    function closeAll(): void {
      scope.popups = [];
    }
    function dismiss(id: int): void {
      scope.popups = scope.popups.filter(n => n.id !== id);
    }
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; right: true }
      margins { top: 0; right: 10 }
      exclusiveZone: 0
      mask: Region {}
      color: "transparent"
      implicitWidth: 320
      implicitHeight: col.implicitHeight

      ColumnLayout {
        id: col
        anchors.top: parent.top
        width: parent.width
        spacing: 8
        Repeater {
          model: scope.popups.filter(n => n !== null && n !== undefined).slice(-4).reverse()
          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: inner.implicitHeight + 16
            color: Theme.bg
            border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.urgent : Theme.border
            border.width: 1
            ColumnLayout {
              id: inner
              anchors.fill: parent
              anchors.margins: 8
              spacing: 4
              RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Image {
                  readonly property string iconName: modelData.appIcon ?? ""
                  source: iconName.includes("://") ? iconName : (iconName ? "image://icon/" + iconName : "image://icon/" + (modelData.appName ?? "application-x-executable"))
                  visible: status === Image.Ready
                  Layout.preferredWidth: 20
                  Layout.preferredHeight: 20
                  sourceSize.width: 20
                  sourceSize.height: 20
                  fillMode: Image.PreserveAspectFit
                }
                Text {
                  text: modelData.summary ?? "Notification"
                  color: Theme.fg
                  font.family: Theme.font
                  font.pixelSize: 12
                  font.bold: true
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
              }
              Text {
                visible: (modelData.body ?? "").length > 0
                text: modelData.body
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 6
                elide: Text.ElideRight
              }
              RowLayout {
                visible: (modelData.actions ?? []).length > 0
                Repeater {
                  model: modelData.actions ?? []
                  Rectangle {
                    required property var modelData
                    implicitWidth: lbl.implicitWidth + 16
                    implicitHeight: 24
                    color: Theme.bgAlt
                    border.color: Theme.border
                    Text { id: lbl; anchors.centerIn: parent; text: parent.modelData.text; color: Theme.fg; font.pixelSize: 11 }
                    MouseArea {
                      anchors.fill: parent
                      onClicked: { modelData.invoke(); }
                    }
                  }
                }
              }
            }
            MouseArea {
              anchors.fill: parent
              z: -1
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                  scope.popups = scope.popups.filter(n => n !== modelData);
                } else {
                  try { modelData.dismiss(); } catch (e) {}
                  scope.popups = scope.popups.filter(n => n !== modelData);
                }
              }
            }
          }
        }
      }
    }
  }
}
