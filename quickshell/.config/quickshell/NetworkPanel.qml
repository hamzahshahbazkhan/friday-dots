import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: scope

    property bool open: false
    property var nets: []
    property bool wifiOn: true
    property string selected: ""
    property string activeSsid: ""
    property string wifiDevice: ""
    property int activeSignal: 0
    property string localIp: ""
    property int focusIndex: 0

    IpcHandler {
        target: "network"

        function toggle(): void {
            scope.open = !scope.open
            if (scope.open)
                refresh()
        }

        function open(): void {
            scope.open = true
            refresh()
        }

        function close(): void {
            scope.open = false
        }
    }

    function refresh() {
        radioProc.running = true
        listProc.running = true
        activeProc.running = true
        ipProc.running = true
        rescanProc.running = true
    }

    Process {
        id: radioProc

        command: ["bash", "-lc", "nmcli radio wifi"]

        stdout: StdioCollector {
            onStreamFinished: {
                scope.wifiOn = this.text.trim() === "enabled"
            }
        }
    }

    Process {
        id: activeProc

        command: [
            "bash",
            "-lc",
            "nmcli -t --escape yes -f DEVICE,TYPE,STATE dev status 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const devices = this.text
                    .trim()
                    .split("\n")
                    .map(line => scope.fields(line))

                const wifi = devices.find(
                    d => d[1] === "wifi" && d[2] === "connected"
                )

                scope.wifiDevice = wifi ? wifi[0] : ""

                if (!scope.wifiDevice) {
                    scope.activeSsid = ""
                    scope.activeSignal = 0
                }

                ipProc.running = true
                activeWifiProc.running = true
            }
        }
    }

    Process {
        id: activeWifiProc

        command: [
            "bash",
            "-lc",
            "nmcli -t --escape yes -f IN-USE,SSID,SIGNAL dev wifi list --rescan no 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text
                    .trim()
                    .split("\n")
                    .find(row => row.startsWith("*:")) || ""

                if (!line)
                    return

                const p = scope.fields(line)

                scope.activeSsid = p[1] || ""
                scope.activeSignal = parseInt(p[2]) || 0
            }
        }
    }

    Process {
        id: ipProc

        command: [
            "bash",
            "-lc",
            "ip -o -4 addr show up scope global 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")

                const line = lines.find(
                    entry => entry.split(/\s+/)[1] === scope.wifiDevice
                ) || ""

                scope.localIp =
                    line.split(/\s+/)[3]?.split("/")[0] || ""
            }
        }
    }

    Process {
        id: listProc

        command: [
            "bash",
            "-lc",
            "nmcli -t --escape yes -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | head -n 40"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const seen = {}

                for (const ln of this.text.trim().split("\n")) {
                    const p = scope.fields(ln)

                    if (p.length < 4)
                        continue

                    const ssid = p[1]

                    if (!ssid || seen[ssid])
                        continue

                    seen[ssid] = true

                    out.push({
                        ssid: ssid,
                        signal: parseInt(p[2]) || 0,
                        sec: p[3] ?? "",
                        active: p[0] === "*"
                    })
                }

                scope.nets = out

                scope.focusIndex = out.length
                    ? Math.min(
                        scope.focusIndex,
                        out.length - 1
                    )
                    : 0
            }
        }
    }

    Process {
        id: rescanProc

        command: [
            "nmcli",
            "dev",
            "wifi",
            "rescan"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                listProc.running = true
            }
        }
    }

    function quote(s) {
        return "'" +
            String(s).replace(/'/g, "'\\''") +
            "'"
    }

    function fields(line) {
        const out = []
        let field = ""
        let escaped = false

        for (const ch of line) {
            if (escaped) {
                field += ch
                escaped = false
            } else if (ch === "\\") {
                escaped = true
            } else if (ch === ":") {
                out.push(field)
                field = ""
            } else {
                field += ch
            }
        }

        if (escaped)
            field += "\\"

        out.push(field)

        return out
    }

    function run(cmd) {
        Quickshell.execDetached([
            "bash",
            "-lc",
            cmd
        ])

        Qt.callLater(() => {
            listProc.running = true
            activeProc.running = true
            ipProc.running = true
        })
    }

    function activateNetwork(n) {
        if (!n)
            return

        if (n.ssid === scope.activeSsid) {
            scope.run(
                "nmcli con down " +
                scope.quote(n.ssid)
            )
        } else if (n.sec === "") {
            scope.run(
                "nmcli dev wifi connect " +
                scope.quote(n.ssid)
            )
        } else {
            scope.selected =
                scope.selected === n.ssid
                    ? ""
                    : n.ssid
        }
    }

    function sigBars(s) {
        if (s >= 75)
            return "▂▄▆"

        if (s >= 50)
            return "▂▄"

        if (s >= 25)
            return "▂"

        return "▁"
    }

    function ensureVisible(index) {
        if (index < 0 || index >= networkList.children.length)
            return

        const item = networkList.children[index]

        if (!item)
            return

        const top = item.y
        const bottom = item.y + item.height

        if (top < networkScroll.contentY) {
            networkScroll.contentY = top
        } else if (
            bottom >
            networkScroll.contentY +
            networkScroll.height
        ) {
            networkScroll.contentY =
                bottom - networkScroll.height
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true

        onTriggered: {
            activeProc.running = true
            ipProc.running = true
            listProc.running = true
        }
    }

    LazyLoader {
        active: scope.open

        PanelWindow {
            id: win

            anchors {
                top: true
                right: true
            }

            margins {
                top: 0
                right: 10
            }

            exclusiveZone: 0

            color: "transparent"

            implicitWidth: 320

            height: 640

            HyprlandFocusGrab {
                windows: [win]
                active: scope.open

                onCleared: {
                    scope.open = false
                }
            }

            Item {
                id: keyboardHandler

                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (scope.selected !== "") {
                            scope.selected = ""
                        } else {
                            scope.open = false
                        }

                        event.accepted = true
                    }

                    else if (
                        event.key === Qt.Key_J ||
                        event.key === Qt.Key_Down
                    ) {
                        if (scope.nets.length) {
                            scope.focusIndex = Math.min(
                                scope.nets.length - 1,
                                scope.focusIndex + 1
                            )

                            scope.ensureVisible(
                                scope.focusIndex
                            )
                        }

                        event.accepted = true
                    }

                    else if (
                        event.key === Qt.Key_K ||
                        event.key === Qt.Key_Up
                    ) {
                        if (scope.nets.length) {
                            scope.focusIndex = Math.max(
                                0,
                                scope.focusIndex - 1
                            )

                            scope.ensureVisible(
                                scope.focusIndex
                            )
                        }

                        event.accepted = true
                    }

                    else if (event.key === Qt.Key_H) {
                        scope.run(
                            "nmcli radio wifi off"
                        )

                        scope.wifiOn = false

                        event.accepted = true
                    }

                    else if (event.key === Qt.Key_L) {
                        scope.run(
                            "nmcli radio wifi on"
                        )

                        scope.wifiOn = true

                        event.accepted = true
                    }

                    else if (
                        event.key === Qt.Key_Return ||
                        event.key === Qt.Key_Enter
                    ) {
                        scope.activateNetwork(
                            scope.nets[
                                scope.focusIndex
                            ]
                        )

                        event.accepted = true
                    }
                }
            }

            Rectangle {
                anchors.fill: parent

                color: Theme.bg
                border.color: Theme.border

                Column {
                    id: mainColumn

                    anchors {
                        fill: parent
                        margins: 9
                    }

                    spacing: 8

                    // ==================================================
                    // HEADER
                    // ==================================================

                    RowLayout {
                        width: parent.width
                        height: 24

                        Text {
                            Layout.fillWidth: true

                            text: "Wi-Fi"

                            color: Theme.fg

                            font.family:
                                Theme.font

                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 48

                            text: "rescan"

                            color: Theme.dim

                            font.family:
                                Theme.font

                            font.pixelSize: 11

                            horizontalAlignment:
                                Text.AlignRight

                            MouseArea {
                                anchors.fill: parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    rescanProc.running = true
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 24

                            color:
                                scope.wifiOn
                                    ? Theme.accent
                                    : Theme.bgAlt

                            border.color:
                                Theme.border

                            Text {
                                anchors.centerIn:
                                    parent

                                text:
                                    scope.wifiOn
                                        ? "on"
                                        : "off"

                                color:
                                    scope.wifiOn
                                        ? Theme.bg
                                        : Theme.muted

                                font.family:
                                    Theme.font

                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    scope.run(
                                        scope.wifiOn
                                            ? "nmcli radio wifi off"
                                            : "nmcli radio wifi on"
                                    )

                                    scope.wifiOn =
                                        !scope.wifiOn
                                }
                            }
                        }
                    }

                    // ==================================================
                    // ACTIVE CONNECTION
                    // ==================================================

                    Text {
                        width: parent.width

                        height:
                            visible
                                ? 16
                                : 0

                        visible:
                            scope.activeSsid !== "" ||
                            scope.localIp !== ""

                        text:
                            (
                                scope.activeSsid ||
                                (
                                    scope.wifiDevice
                                        ? "Connected"
                                        : "Disconnected"
                                )
                            )
                            +
                            (
                                scope.wifiDevice
                                    ? "  ·  " +
                                      scope.activeSignal +
                                      "%"
                                    : ""
                            )
                            +
                            (
                                scope.localIp
                                    ? "  ·  " +
                                      scope.localIp
                                    : ""
                            )

                        color: Theme.dim

                        font.family:
                            Theme.font

                        font.pixelSize: 10

                        elide:
                            Text.ElideRight
                    }

                    // ==================================================
                    // NETWORK VIEWPORT
                    //
                    // Fixed height prevents the implicit-height
                    // recursion that was making the panel disappear.
                    // ==================================================

                    Item {
                        id: networkViewport

                        width: parent.width

                        height: 550

                        clip: true

                        // ==================================================
                        // FLICKABLE
                        // ==================================================

                        Flickable {
                            id: networkScroll

                            anchors.fill: parent

                            clip: true

                            contentWidth:
                                networkList.width

                            contentHeight:
                                networkList.height

                            flickableDirection:
                                Flickable.VerticalFlick

                            boundsBehavior:
                                Flickable.StopAtBounds

                            Column {
                                id: networkList

                                width:
                                    networkViewport.width - 8

                                spacing: 2

                                Repeater {
                                    model: scope.nets

                                    Column {
                                        required property var modelData
                                        required property int index

                                        width:
                                            networkList.width

                                        spacing: 2

                                        // ----------------------------------
                                        // NETWORK ROW
                                        // ----------------------------------

                                        Rectangle {
                                            width: parent.width

                                            height: 28

                                            color:
                                                modelData.ssid ===
                                                    scope.activeSsid ||
                                                scope.focusIndex ===
                                                    index
                                                    ? Theme.bgAlt
                                                    : "transparent"

                                            border.color:
                                                scope.focusIndex ===
                                                    index
                                                    ? Theme.accent
                                                    : (
                                                        modelData.ssid ===
                                                            scope.activeSsid
                                                            ? Theme.border
                                                            : "transparent"
                                                    )

                                            RowLayout {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: 8
                                                    rightMargin: 8
                                                }

                                                spacing: 8

                                                Text {
                                                    text:
                                                        modelData.ssid ===
                                                            scope.activeSsid
                                                            ? "●"
                                                            : "○"

                                                    color:
                                                        Theme.accent

                                                    font.pixelSize: 10
                                                }

                                                Text {
                                                    Layout.fillWidth: true

                                                    text:
                                                        modelData.ssid

                                                    color:
                                                        Theme.fg

                                                    font.family:
                                                        Theme.font

                                                    font.pixelSize: 12

                                                    elide:
                                                        Text.ElideRight
                                                }

                                                Text {
                                                    visible: modelData.sec !== ""

                                                    text:
                                                        ""

                                                    color:
                                                        Theme.fg

                                                    font.pixelSize: 10
                                                }

                                                Text {
                                                    id: signalText
                                                    Layout.minimumWidth: 28
                                                    horizontalAlignment: Text.AlignRight

                                                    text:
                                                        scope.sigBars(
                                                            modelData.signal
                                                        )

                                                    color:
                                                        Theme.dim

                                                    font.family:
                                                        Theme.font

                                                    font.pixelSize: 10
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill:
                                                    parent

                                                cursorShape:
                                                    Qt.PointingHandCursor

                                                onClicked: {
                                                    scope.focusIndex =
                                                        index

                                                    scope.activateNetwork(
                                                        modelData
                                                    )
                                                }
                                            }
                                        }

                                        // ----------------------------------
                                        // PASSWORD
                                        // ----------------------------------

                                        Item {
                                            visible:
                                                scope.selected ===
                                                modelData.ssid

                                            width:
                                                parent.width

                                            height:
                                                visible ? 30 : 0

                                            TextInput {
                                                id: passwordInput

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    leftMargin: 6
                                                    rightMargin: 6
                                                }

                                                height: 26

                                                color:
                                                    Theme.fg

                                                font.family:
                                                    Theme.font

                                                font.pixelSize: 12

                                                echoMode:
                                                    TextInput.Password

                                                focus:
                                                    scope.selected ===
                                                    modelData.ssid

                                                onAccepted: {
                                                    scope.run(
                                                        "nmcli dev wifi connect " +
                                                        scope.quote(
                                                            modelData.ssid
                                                        ) +
                                                        " password " +
                                                        scope.quote(
                                                            text
                                                        )
                                                    )

                                                    scope.selected = ""
                                                    text = ""
                                                }

                                                Keys.onPressed: e => {
                                                    if (
                                                        e.key ===
                                                        Qt.Key_Escape
                                                    ) {
                                                        scope.selected = ""
                                                        e.accepted = true
                                                    }
                                                }

                                                Rectangle {
                                                    anchors {
                                                        left: parent.left
                                                        right: parent.right
                                                        bottom: parent.bottom
                                                    }

                                                    height: 1

                                                    color:
                                                        Theme.border
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ==================================================
                            // MOUSE WHEEL
                            // ==================================================

                            WheelHandler {
                                onWheel: event => {
                                    const maxY =
                                        Math.max(
                                            0,
                                            networkScroll.contentHeight -
                                            networkScroll.height
                                        )

                                    networkScroll.contentY =
                                        Math.max(
                                            0,
                                            Math.min(
                                                maxY,
                                                networkScroll.contentY -
                                                event.angleDelta.y
                                            )
                                        )

                                    event.accepted = true
                                }
                            }
                        }

                        // ==================================================
                        // SCROLLBAR
                        // ==================================================

                        Rectangle {
                            id: scrollTrack

                            visible:
                                networkScroll.contentHeight >
                                networkScroll.height

                            anchors {
                                top: parent.top
                                right: parent.right
                                bottom: parent.bottom
                            }

                            width: 4

                            color:
                                Theme.bgAlt

                            radius: 2

                            Rectangle {
                                id: scrollThumb

                                width: parent.width

                                height:
                                    Math.max(
                                        25,
                                        parent.height *
                                        (
                                            networkScroll.height /
                                            networkScroll.contentHeight
                                        )
                                    )

                                y:
                                    (
                                        networkScroll.contentHeight >
                                        networkScroll.height
                                    )
                                    ? (
                                        networkScroll.contentY /
                                        (
                                            networkScroll.contentHeight -
                                            networkScroll.height
                                        )
                                    ) *
                                    (
                                        parent.height -
                                        height
                                    )
                                    : 0

                                color:
                                    Theme.border

                                radius: 2
                            }
                        }
                    }

                    // ==================================================
                    // EMPTY STATE
                    // ==================================================

                    Text {
                        width: parent.width

                        height:
                            scope.nets.length === 0
                                ? 16
                                : 0

                        visible:
                            scope.nets.length === 0

                        text:
                            scope.wifiOn
                                ? "no networks — rescan?"
                                : "wi-fi is off"

                        color:
                            Theme.dim

                        font.family:
                            Theme.font

                        font.pixelSize:
                            11
                    }
                }
            }
        }
    }
}
