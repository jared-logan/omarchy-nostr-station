import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "nostr.station"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property var service: hostWidget ? hostWidget.stationService : null
  readonly property bool isRunning: service ? service.running : false
  readonly property bool isInstalled: service ? service.installed : false
  readonly property bool isInstalling: service ? service.installing : false
  readonly property string statusText: service ? service.statusText : "loading..."

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function closeForPopoutSwitch() { root.close() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        Text {
          width: parent.width
          text: "Nostr Station"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: root.statusText
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: Style.space(8)

          Button {
            text: {
              if (root.isInstalling) return "Installing..."
              if (!root.isInstalled) return "Install"
              if (root.isRunning) return "Stop"
              return "Start"
            }
            enabled: !root.isInstalling
            foreground: root.barForeground
            onClicked: {
              if (!root.service) return
              if (root.isRunning) root.service.stop()
              else root.service.start()
            }
          }

          Button {
            text: "Restart"
            enabled: root.isInstalled && !root.isInstalling
            foreground: root.barForeground
            onClicked: {
              if (root.service) root.service.restart()
            }
          }

          Button {
            text: "Open Dashboard"
            enabled: root.isRunning
            foreground: root.barForeground
            onClicked: {
              if (root.service) root.service.open()
            }
          }
        }

        Text {
          width: parent.width
          visible: !root.isInstalled
          text: "Nostr Station is not installed. Click Install to download and build it."
          color: Qt.darker(root.barForeground, 1.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
