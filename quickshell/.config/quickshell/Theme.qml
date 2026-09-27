pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  FileView {
    id: themeFile
    path: Quickshell.env("HOME") + "/.config/themes/current/quickshell.json"
    watchChanges: true
    blockLoading: true
    onFileChanged: themeFile.reload()
    onLoadFailed: error => console.warn("Theme: failed to load quickshell.json, using defaults: " + error)
  }

  readonly property var data: {
    try {
      const t = themeFile.text();
      if (t && t.length > 2) return JSON.parse(t);
    } catch (e) {
      console.warn("Theme: JSON parse failed, using defaults: " + e);
    }
    return {};
  }

  // Defaults match hamza theme (gruvbox-ish dark)
  readonly property string bg: data.background ?? "#1d2021"
  readonly property string bgAlt: data.backgroundAlt ?? "#282828"
  readonly property string fg: data.foreground ?? "#d4cfc4"
  readonly property string muted: data.muted ?? "#7c6f64"
  readonly property color dim: Qt.lighter(muted, 2.4)
  readonly property string accent: data.accent ?? "#7d8f9d"
  readonly property string accent2: data.accent2 ?? "#6f8781"
  readonly property string urgent: data.urgent ?? "#d2788c"
  readonly property string border: data.border ?? "#3c3836"
  readonly property string font: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 10
  readonly property int barHeight: 22
}
