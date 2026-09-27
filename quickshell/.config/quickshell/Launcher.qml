import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets

// App launcher.
Scope {
  id: scope
  property bool open: false

  IpcHandler {
    target: "launcher"
    function toggle(): void { scope.open = !scope.open; }
    function open(): void { scope.open = true; }
    function close(): void { scope.open = false; }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "launcher-toggle"
    description: "Toggle app launcher"
    onPressed: scope.open = !scope.open
  }

  function runCmd(cmd) {
    Quickshell.execDetached(["bash", "-lc", cmd]);
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
        id: grab
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
        implicitWidth: 440
        implicitHeight: 370
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 8

          // ================= APPS =================
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            TextInput {
              id: query
              Layout.fillWidth: true
              color: Theme.fg
              font.family: Theme.font
              font.pixelSize: 13
              focus: true
              onAccepted: {
                if (list.count > 0) list.itemAtIndex(0).runApp();
              }
              onTextChanged: list.currentIndex = 0
              Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) scope.open = false;
                else if (event.key === Qt.Key_Tab) list.forceActiveFocus();
                else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) list.currentIndex = Math.max(0, list.currentIndex - 1);
              }
              Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -6 }
                height: 1
                color: Theme.border
              }
            }
            ListView {
              id: list
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 2
              focus: true
              model: ScriptModel {
                values: {
                  const q = query.text.toLowerCase().trim();
                  const apps = (DesktopEntries.applications.values ?? []).filter(a => !a.noDisplay && a.id !== "xfce4-about");
                  const actions = [
                    { name: "Keybindings and shortcuts", genericName: "Search keyboard shortcuts", comment: "Open searchable keybinding reference", keybindingsAction: true },
                    { name: "Switch theme", genericName: "Theme colors palette", comment: "Browse and apply color themes", themeAction: true },
                    { name: "Switch wallpaper", genericName: "Wallpaper images", comment: "Browse wallpaper thumbnails", wallpaperAction: true }
                  ];
                  const entries = actions.concat(apps);
                  if (!q) return entries;
                  return entries.filter(entry => {
                    const hay = ((entry.name ?? "") + " " + (entry.genericName ?? "") + " " + (entry.comment ?? "")).toLowerCase();
                    return hay.includes(q);
                  });
                }
                onValuesChanged: list.currentIndex = 0
              }
              delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                implicitHeight: 34
                radius: 0
                color: list.currentIndex === index ? Theme.bgAlt : "transparent"
                function runApp() {
                  if (modelData.keybindingsAction) {
                    scope.open = false;
                    Quickshell.execDetached(["quickshell", "ipc", "call", "keybindings", "open"]);
                    return;
                  }
                  if (modelData.themeAction || modelData.wallpaperAction) {
                    scope.open = false;
                    Quickshell.execDetached(["quickshell", "ipc", "call", modelData.themeAction ? "themes" : "wallpapers", "open"]);
                    return;
                  }
                  try { modelData.execute(); } catch (e) { console.warn(e); }
                  scope.open = false;
                  query.text = "";
                }
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 5
                  spacing: 10
                  IconImage { visible: !modelData.keybindingsAction && !modelData.themeAction && !modelData.wallpaperAction; source: visible && modelData.icon ? Quickshell.iconPath(modelData.icon) : ""; implicitSize: 24 }
                  Text { visible: !!modelData.keybindingsAction; text: "⌘"; color: Theme.accent; font.pixelSize: 20 }
                  Text { visible: !!modelData.themeAction; text: "◉"; color: Theme.accent; font.pixelSize: 20 }
                  Text { visible: !!modelData.wallpaperAction; text: "▧"; color: Theme.accent; font.pixelSize: 20 }
                  Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.name
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { list.currentIndex = index; parent.runApp(); }
                }
              }
              Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) scope.open = false;
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) list.currentIndex = Math.max(0, list.currentIndex - 1);
                else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                  if (list.count > 0) list.itemAtIndex(list.currentIndex).runApp();
                }
              }
            }
          }

        }
      }
      Component.onCompleted: query.forceActiveFocus()
    }
  }
}
