import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Io

Scope {
  id: barScope
  property var visibleWs: {
    const vals = Hyprland.workspaces.values ?? [];
    const focusedId = Hyprland.focusedWorkspace?.id ?? -1;
    const extra = [];
    for (const w of vals) {
      if (!w || w.id <= 5) continue;
      if ((w.toplevels?.values?.length ?? 0) > 0 || w.id === focusedId) extra.push(w.id);
    }
    if (focusedId > 5 && !extra.includes(focusedId)) extra.push(focusedId);
    extra.sort((a, b) => a - b);
    return [1, 2, 3, 4, 5].concat(extra);
  }
  property string activeSsid: ""
  property string netAddr: ""
  property string netIface: ""
  property string netType: "none" // "wifi" | "ethernet" | "none"
  property int wifiSignal: 0
  property bool bluetoothOn: false
  property int cpuPercent: 0
  property var cpuCores: []
  property var prevCoreIdle: []
  property var prevCoreTotal: []
  property string ramText: "--"
  property real ramPercent: 0
  property real ramTotalGB: 0
  property real ramUsedGB: 0
  property double previousIdle: 0
  property double previousTotal: 0
  property bool longDate: false
  property bool trayExpanded: false

  PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

  Process {
    id: addrProc
    command: ["bash", "-lc", "nmcli -t --escape yes -f DEVICE,TYPE,STATE dev status 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const devices = this.text.trim().split("\n").map(line => barScope.fields(line));
        const active = devices.find(d => d[2] === "connected");
        const wifi = devices.find(d => d[1] === "wifi" && d[2] === "connected");
        barScope.netIface = active ? active[0] : "";
        barScope.netType = wifi ? "wifi" : (active ? "ethernet" : "none");
        ipProc.running = true;
        if (barScope.netType === "wifi") {
          wifiInfoProc.running = true;
        } else {
          barScope.activeSsid = "";
          barScope.wifiSignal = 0;
        }
      }
    }
    running: true
  }
  Process {
    id: wifiInfoProc
    command: ["bash", "-lc", "nmcli -t --escape yes -f IN-USE,SSID,SIGNAL dev wifi list --rescan no 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const line = this.text.trim().split("\n").find(row => row.startsWith("*:")) || "";
        if (!line) return;
        const p = barScope.fields(line);
        barScope.activeSsid = p[1] || "";
        barScope.wifiSignal = parseInt(p[2]) || 0;
      }
    }
  }
  Process {
    id: ipProc
    command: ["bash", "-lc", "ip -o -4 addr show up scope global 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n");
        const line = lines.find(entry => entry.split(/\s+/)[1] === barScope.netIface) || "";
        const fields = line.split(/\s+/);
        barScope.netAddr = fields[3]?.split("/")[0] || "";
      }
    }
  }
  Process {
    id: statsProc
    command: ["cat", "/proc/stat", "/proc/meminfo"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.split("\n");

        const agg = (lines[0] ?? "").trim().split(/\s+/).slice(1).map(Number);
        if (agg.length >= 4) {
          const idle = agg[3] + (agg[4] ?? 0);
          const total = agg.reduce((a, b) => a + b, 0);
          if (barScope.previousTotal > 0 && total > barScope.previousTotal)
            barScope.cpuPercent = Math.round(100 * (1 - (idle - barScope.previousIdle) / (total - barScope.previousTotal)));
          barScope.previousIdle = idle;
          barScope.previousTotal = total;
        }

        const coreLines = lines.filter(l => /^cpu\d+ /.test(l));
        if (barScope.prevCoreIdle.length !== coreLines.length) {
          barScope.prevCoreIdle = coreLines.map(() => 0);
          barScope.prevCoreTotal = coreLines.map(() => 0);
        }
        const newCores = [];
        coreLines.forEach((l, i) => {
          const vals = l.trim().split(/\s+/).slice(1).map(Number);
          if (vals.length < 4) return;
          const idle = vals[3] + (vals[4] ?? 0);
          const total = vals.reduce((a, b) => a + b, 0);
          const prevIdle = barScope.prevCoreIdle[i] ?? 0;
          const prevTotal = barScope.prevCoreTotal[i] ?? 0;
          let pct = barScope.cpuCores[i]?.percent ?? 0;
          if (prevTotal > 0 && total > prevTotal)
            pct = Math.round(100 * (1 - (idle - prevIdle) / (total - prevTotal)));
          barScope.prevCoreIdle[i] = idle;
          barScope.prevCoreTotal[i] = total;
          newCores.push({ index: i, percent: pct });
        });
        barScope.cpuCores = newCores;

        let totalMem = 0, available = 0;
        for (const line of lines) {
          if (line.startsWith("MemTotal:")) totalMem = parseInt(line.split(/\s+/)[1]) || 0;
          if (line.startsWith("MemAvailable:")) available = parseInt(line.split(/\s+/)[1]) || 0;
        }
        if (totalMem > 0) {
          barScope.ramText = ((totalMem - available) / 1048576).toFixed(1) + "G";
          barScope.ramPercent = Math.round(100 * (totalMem - available) / totalMem);
          barScope.ramTotalGB = totalMem / 1048576;
          barScope.ramUsedGB = (totalMem - available) / 1048576;
        }
      }
    }
    running: true
  }
  Process {
    id: bluetoothProc
    command: ["bash", "-lc", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo yes || echo no"]
    stdout: StdioCollector { onStreamFinished: barScope.bluetoothOn = this.text.trim() === "yes" }
  }
  Timer {
    interval: 3000; running: true; repeat: true
    onTriggered: statsProc.running = true
  }
  Timer {
    interval: 15000; running: true; repeat: true
    onTriggered: {
      addrProc.running = true
      if (barScope.netType === "wifi") wifiInfoProc.running = true
      bluetoothProc.running = true
    }
  }

  Process { id: pavuProc; command: ["pavucontrol"] }
  Process { id: btopProc; command: ["ghostty", "--title=BtopFloat", "-e", "btop"] }
  readonly property string gMic: "󰍬"

  function warnColorHigh(pct) {
    if (pct >= 85) return Theme.urgent
    if (pct >= 65) return "#e5b567"
    return Theme.fg
  }
  function batColor(pct) {
    if (pct <= 10) return Theme.urgent
    if (pct <= 20) return "#e5b567"
    return Theme.fg
  }
  function isHeadphone() {
    const desc = ((Pipewire.defaultAudioSink?.description ?? "") + " " + (Pipewire.defaultAudioSink?.nickname ?? "")).toLowerCase()
    return desc.includes("headphone") || desc.includes("headset") || desc.includes("earphone") || desc.includes("earbud")
  }
  function fields(line) {
    const out = []; let field = ""; let escaped = false;
    for (const ch of line) {
      if (escaped) { field += ch; escaped = false; }
      else if (ch === "\\") escaped = true;
      else if (ch === ":") { out.push(field); field = ""; }
      else field += ch;
    }
    out.push(field);
    return out;
  }
  function cpuTooltip() {
    if (!barScope.cpuCores.length) return "cpu " + barScope.cpuPercent + "%"
    return barScope.cpuCores.map(c => "core " + c.index + ": " + c.percent + "%").join("\n")
  }
  function ramTooltip() {
    return "used " + barScope.ramUsedGB.toFixed(1) + "g / " + barScope.ramTotalGB.toFixed(1) + "g (" + barScope.ramPercent + "%)"
  }
  function netTooltip() {
    if (barScope.netType === "wifi")
      return (barScope.activeSsid || "wifi") + " · signal " + barScope.wifiSignal + "%" + (barScope.netAddr ? "\n" + barScope.netAddr : "")
    if (barScope.netType === "ethernet")
      return "wired connection" + (barScope.netAddr ? "\n" + barScope.netAddr : "")
    return "no network connection"
  }

  component DropMenu: PopupWindow {
    id: menu
    color: "transparent"
    default property alias content: menuColumn.data
    width: menuBg.implicitWidth
    height: menuBg.implicitHeight
    property bool pointerInside: false
    Rectangle {
      id: menuBg
      width: parent.width
      height: parent.height
      implicitWidth: Math.max(130, menuColumn.implicitWidth + 24)
      implicitHeight: menuColumn.implicitHeight + 16
      color: Theme.bg
      border.color: Theme.border
      ColumnLayout {
        id: menuColumn
        anchors.centerIn: parent
        spacing: 4
      }
      HoverHandler { onHoveredChanged: menu.pointerInside = hovered }
    }
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: win
      required property var modelData
      screen: modelData
      anchors { top: true; left: true; right: true }
      implicitHeight: Theme.barHeight
      color: Theme.bg
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
      }

      Item {
        anchors.fill: parent
        RowLayout {
          id: leftSide
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 8
          Text {
            text: "󰣇"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "launcher", "toggle"]); cursorShape: Qt.PointingHandCursor }
          }
          RowLayout {
            spacing: 3
            Repeater {
              model: barScope.visibleWs
              Rectangle {
                required property int index
                required property var modelData
                property int wsId: modelData
                property var ws: {
                  const vals = Hyprland.workspaces.values ?? [];
                  for (const w of vals) if (w && w.id === wsId) return w;
                  return null;
                }
                property bool isFocused: (Hyprland.focusedWorkspace?.id ?? -1) === wsId
                property bool occupied: ws !== null && (ws.toplevels?.values?.length ?? 0) > 0
                implicitWidth: 20; implicitHeight: 18
                color: isFocused ? Theme.accent : "transparent"
                Text { anchors.centerIn: parent; text: parent.wsId; color: parent.isFocused ? Theme.bg : Theme.fg; opacity: parent.isFocused ? 1 : (parent.occupied ? 0.8 : 0.4); font.family: Theme.font; font.pixelSize: Theme.fontSize }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("workspace " + parent.wsId) }
              }
            }
          }
          Text {
            id: mediaText
            visible: (Mpris.players.values?.length ?? 0) > 0
            Layout.maximumWidth: Math.max(140, parent.width * 0.40)
            text: {
              const ps = Mpris.players.values ?? [];
              if (!ps.length) return "";
              const p = ps[0];
              return "󰎈  " + (p.trackTitle ?? "") + (p.trackArtist ? "  ·  " + p.trackArtist : "");
            }
            color: Theme.fg; opacity: 0.80; elide: Text.ElideRight
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            MouseArea {
              anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
              onClicked: mouse => {
                const p = (Mpris.players.values ?? [])[0];
                if (!p) return;
                if (mouse.button === Qt.RightButton) p.togglePlaying();
                else Quickshell.execDetached(["quickshell", "ipc", "call", "media", "toggle"]);
              }
            }
          }
        }

        Text {
          id: clockText
          anchors.centerIn: parent
          text: Qt.formatDateTime(clock.date, barScope.longDate ? "dddd, MMMM d  ·  h:mm AP" : "ddd dd  hh:mm")
          color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize
          SystemClock { id: clock; precision: SystemClock.Seconds }
          MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) barScope.longDate = !barScope.longDate;
              else Quickshell.execDetached(["quickshell", "ipc", "call", "calendar", "toggle"]);
            }
          }
        }

        // Less-used controls stay tucked beside the clock until hover.
        Item {
          id: utilityArea
          anchors { left: clockText.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
          width: 110; height: parent.height
          HoverHandler { id: utilityHover }
          RowLayout {
            anchors.centerIn: parent; spacing: 13
            Text {
              visible: utilityHover.hovered
              text: barScope.gMic
              color: Theme.muted
              opacity: 0.8
              font.family: Theme.font; font.pixelSize: Theme.fontSize
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]) }
            }
            Text {
              visible: utilityHover.hovered
              text: "󰌵"
              color: Theme.muted
              opacity: 0.8
              font.family: Theme.font; font.pixelSize: Theme.fontSize
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: {
                  const p = nightlightGlyph.mapToItem(null, 0, nightlightGlyph.height);
                  Quickshell.execDetached(["quickshell", "ipc", "call", "nightlight", "openAt", String(Math.round(p.x)), String(Math.max(Theme.barHeight, p.y))]);
                }
              }
              id: nightlightGlyph
            }
            Text {
              visible: utilityHover.hovered; text: "⏻"; color: Theme.muted; opacity: 0.8; font.pixelSize: 13
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "powermenu", "toggle"]) }
            }
          }
        }

        RowLayout {
          id: rightSide
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 10

          // Hidden tray: click the arrow to reveal running background apps (Telegram etc.)
          RowLayout {
            spacing: 6
            RowLayout {
              visible: barScope.trayExpanded
              spacing: 5
              Repeater {
                model: SystemTray.items
                Item {
                  id: trayIcon
                  required property var modelData
                  implicitWidth: 14; implicitHeight: 14
                  HoverHandler { id: trayHover }
                  Image {
                    anchors.centerIn: parent
                    width: 12; height: 12
                    sourceSize.width: 24
                    sourceSize.height: 24
                    source: modelData.icon ?? ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: 0.55
                  }
                  DropMenu {
                    id: trayMenu
                    anchor.item: parent
                    anchor.edges: Edges.Bottom | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                    visible: trayHover.hovered || pointerInside
                    Text { text: modelData.tooltipTitle || modelData.id || "application"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
                  }
                  QsMenuAnchor {
                    id: trayContextMenu
                    menu: trayIcon.modelData.menu
                    anchor.item: trayIcon
                    anchor.edges: Edges.Bottom | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                  }
                  MouseArea {
                    id: trayMouse
                    anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                      if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) trayContextMenu.open();
                        else modelData.secondaryActivate?.();
                      } else {
                        modelData.activate?.();
                      }
                    }
                  }
                }
              }
            }
            Text {
              text: barScope.trayExpanded ? "›" : "‹"
              color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: barScope.trayExpanded = !barScope.trayExpanded }
            }
          }

          Text {
            id: cpuChip
            text: "cpu " + barScope.cpuPercent + "%"
            color: cpuHover.hovered ? Theme.accent : barScope.warnColorHigh(barScope.cpuPercent)
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            HoverHandler { id: cpuHover }
            MouseArea { id: cpuMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: btopProc.running = true }
          }
          Text {
            id: ramChip
            text: "ram " + barScope.ramText
            color: ramHover.hovered ? Theme.accent : barScope.warnColorHigh(barScope.ramPercent)
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            HoverHandler { id: ramHover }
            MouseArea { id: ramMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: btopProc.running = true }
          }
          Item {
            id: netChip
            implicitWidth: networkContent.implicitWidth
            implicitHeight: networkContent.implicitHeight
            RowLayout {
              id: networkContent
              anchors.fill: parent
              spacing: 5
              Text {
                text: barScope.netType === "wifi" ? "wfi" : (barScope.netType === "ethernet" ? "eth" : "off")
                color: netHover.hovered ? Theme.accent : (barScope.netType === "none" ? Theme.dim : Theme.fg)
                font.family: Theme.font; font.pixelSize: Theme.fontSize
              }
              Item {
                visible: barScope.netType === "wifi"
                Layout.preferredWidth: 15
                Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
                Repeater {
                  model: [4, 7, 10, 12]
                  Rectangle {
                    required property int modelData
                    required property int index
                    x: index * 4
                    y: 12 - modelData
                    width: 3
                    height: modelData
                    color: netHover.hovered ? Theme.accent : Theme.fg
                    opacity: barScope.wifiSignal > index * 25 ? 1 : 0.35
                  }
                }
              }
            }
            HoverHandler { id: netHover }
            MouseArea { id: netMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "network", "open"]) }
          }
          Text {
            id: btChip
            text: "bth"
            color: btHover.hovered ? Theme.accent : (barScope.bluetoothOn ? Theme.fg : Theme.dim)
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            HoverHandler { id: btHover }
            MouseArea { id: btMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "bluetooth", "open"]) }
          }
          Text {
            id: volChip
            property var sink: Pipewire.defaultAudioSink?.audio
            text: (barScope.isHeadphone() ? "hdp " : "vol ") + (sink ? Math.round(sink.volume * 100) + "%" : "--")
            color: volHover.hovered ? Theme.accent : (sink?.muted ? Theme.urgent : Theme.fg)
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            HoverHandler { id: volHover }
            MouseArea {
              id: volMouse
              anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton; cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: mouse => {
                const s = Pipewire.defaultAudioSink?.audio;
                if (mouse.button === Qt.RightButton && s) s.muted = !s.muted;
                else if (mouse.button === Qt.MiddleButton) pavuProc.running = true;
                else Quickshell.execDetached(["quickshell", "ipc", "call", "audio", "toggle"]);
              }
              onWheel: wheel => { const s = Pipewire.defaultAudioSink?.audio; if (s) s.volume = Math.max(0, Math.min(1, s.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))); }
            }
          }
          Text {
            id: batteryText
            readonly property int pct: Math.round((UPower.displayDevice?.percentage ?? 0) * 100)
            readonly property bool charging: UPower.displayDevice?.state === UPowerDeviceState.Charging
            visible: UPower.displayDevice?.isLaptopBattery !== false
            text: "bat " + pct + "%" + (charging ? " c" : "")
            color: batteryHover.hovered ? Theme.accent : barScope.batColor(pct)
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            HoverHandler { id: batteryHover }
            MouseArea { id: batteryMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "power", "open"]) }
          }
        }

        DropMenu {
          anchor.item: cpuChip
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: cpuHover.hovered || pointerInside
          Text { text: barScope.cpuTooltip(); color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
        DropMenu {
          anchor.item: ramChip
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: ramHover.hovered || pointerInside
          Text { text: barScope.ramTooltip(); color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
        DropMenu {
          anchor.item: netChip
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: netHover.hovered || pointerInside
          Text { text: barScope.netTooltip(); color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
        DropMenu {
          anchor.item: btChip
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: btHover.hovered || pointerInside
          Text { text: barScope.bluetoothOn ? "bluetooth on" : "bluetooth off"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
        DropMenu {
          anchor.item: volChip
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: volHover.hovered || pointerInside
          Text { text: Pipewire.defaultAudioSink?.description ?? "output device"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
        DropMenu {
          anchor.item: batteryText
          anchor.edges: Edges.Bottom | Edges.Left
          anchor.gravity: Edges.Bottom | Edges.Right
          visible: batteryHover.hovered || pointerInside
          Text { text: "battery " + batteryText.pct + "%" + (batteryText.charging ? " · charging" : ""); color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
      }
    }
  }
}
