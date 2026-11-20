import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.weather"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  // Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
  // requires open/close/opened on the bar-widget root). Open maps to the
  // panel's hotkey path so summoning suppresses the center hover reveal,
  // matching what the old per-plugin IpcHandler did.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  // The panel already resolves the current conditions (the fast open-meteo
  // reading first, wttr.in as fallback). Show that temperature right of the
  // condition icon, and leave it out in a vertical bar where a label would
  // not fit.
  readonly property bool showTemperature: setting("showTemperature", true) !== false
  readonly property string temperatureText: {
    if (!showTemperature || vertical) return ""
    var panel = panelLoader.item
    if (!panel || !panel.reportTempNum) return ""
    return panel.reportTempNum + panel.tempUnit
  }

  function handlePress(button) {
    if (!root.bar) return
    if (button === Qt.RightButton) root.bar.run("omarchy-notification-send \"$(omarchy-weather-status)\"")
    else if (button === Qt.MiddleButton) root.refresh()
    else root.togglePanel()
  }

  // The bar's press overlay hit-tests registered click targets, then falls
  // back to the slot's widget. Exposing triggerPress keeps a press on the
  // temperature label (which sits outside the icon button) working.
  function triggerPress(button) {
    root.handlePress(button)
  }

  // Set by the bar's press overlay while it holds this widget down.
  property int heldButtons: Qt.NoButton

  visible: panelLoader.item && panelLoader.item.label !== ""
  implicitWidth: button.implicitWidth
    + (temperatureLabel.visible ? Style.space(2) + temperatureLabel.implicitWidth : 0)
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    bar: root.bar
    text: panelLoader.item ? panelLoader.item.label : ""
    slotSize: Style.bar.statusSlot
    // Tooltip suppressed because the panel is the detail view.
    tooltipText: ""

    onPressed: function(b) {
      root.handlePress(b)
    }
  }

  Text {
    id: temperatureLabel
    anchors.left: button.right
    anchors.leftMargin: Style.space(2)
    anchors.verticalCenter: parent.verticalCenter
    // Center the figure height rather than the line box, as the bar icons do.
    anchors.verticalCenterOffset: (temperatureMetrics.descent - temperatureMetrics.ascent
      + temperatureMetrics.tightBoundingRect("0").height) / 2
    visible: root.temperatureText !== ""
    textFormat: Text.PlainText
    text: root.temperatureText
    color: root.bar ? root.bar.barForeground : Commons.Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.bar.iconFont
    renderType: Text.NativeRendering
    scale: (root.heldButtons & Qt.LeftButton) ? 0.9 : 1
  }

  FontMetrics {
    id: temperatureMetrics
    font: temperatureLabel.font
  }

  // The bar's press overlay only takes the left button; keep the weather
  // widget's right-click (notification) and middle-click (refresh) shortcuts
  // working across the label too.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton | Qt.MiddleButton
    onClicked: function(mouse) {
      root.handlePress(mouse.button)
    }
  }
}
