import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(3)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: keycap
        required property int modelData
        readonly property var synthColors: ["#c77737", "#cc9947", "#c7b478", "#50653d", "#506b78"]
        readonly property color keyColor: synthColors[(modelData - 1) % synthColors.length]

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        // Active = full brightness, inactive = 35% brightness. Brightness dims
        // the fill and legend together; occupancy uses a separate bottom-edge
        // highlight so it stays visible on dimmed buttons. Hover only shifts
        // the border so an inactive button never reads as active.
        readonly property color baseForeground: modelData % 5 === 4 || modelData % 5 === 0 ? "#f3e6cd" : "#171410"
        readonly property color buttonColor: keycap.focused ? keycap.keyColor : Qt.darker(keycap.keyColor, 2.85)
        readonly property color dimLegend: keycap.focused ? keycap.baseForeground : Qt.darker(keycap.baseForeground, 2.85)

        bar: root.bar
        text: modelData === 10 ? "0" : String(modelData)
        foreground: keycap.dimLegend
        opacity: 1
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(25)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        Rectangle {
          z: -1
          anchors.fill: parent
          anchors.topMargin: Style.space(4)
          anchors.bottomMargin: Style.space(4)
          radius: 2
          color: keycap.buttonColor
          border.width: 1
          border.color: keycap.focused ? "#ffd58a" : (keycap.tooltipHovered ? Qt.darker(keycap.keyColor, 1.9) : Qt.darker(keycap.keyColor, 2.5))
          layer.enabled: keycap.focused
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#ffad42"
            shadowOpacity: 0.42
            shadowBlur: 0.35
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 8
          }
          Rectangle {
            visible: keycap.occupied
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            height: 3
            radius: 1
            color: "#ffad42"
            opacity: keycap.focused ? 0.95 : 0.75
          }
        }
      }
    }
  }
}
