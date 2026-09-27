import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  property string hint: ""
  property bool expanded: false
  Layout.fillWidth: true
  spacing: 4

  Text {
    text: root.expanded ? "▴" : "▾"
    color: Theme.dim
    font.pixelSize: 10
    Layout.alignment: Qt.AlignHCenter
    MouseArea {
      anchors.fill: parent
      anchors.margins: -6
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }
  Text {
    visible: root.expanded
    text: root.hint
    color: Theme.dim
    font.family: Theme.font
    font.pixelSize: 10
    wrapMode: Text.Wrap
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
  }
}
