import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.jotenakis2.myweather"

  // ---- panes ------------------------------------------------------------
  // The data panel and the settings menu are separate panels: only one is
  // open at a time, and both anchor under this widget.

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  function injectSettings() {
    var target = settingsLoader.item
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
    if (settingsOpen) closeSettings()
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  // Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
  // requires open/close/opened on the bar-widget root). Open maps to the
  // panel's hotkey path so summoning suppresses the center hover reveal,
  // matching what the old per-plugin IpcHandler did.
  readonly property bool opened: (panelLoader.item && panelLoader.item.opened === true)
    || (settingsLoader.item && settingsLoader.item.opened === true)

  function open() {
    if (settingsOpen) closeSettings()
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (settingsOpen) {
      closeSettings()
      return
    }
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  // ---- settings menu (right click) --------------------------------------

  readonly property bool settingsOpen: settingsLoader.item ? settingsLoader.item.opened === true : false

  function openSettings() {
    if (!settingsLoader.active) settingsLoader.active = true
    var menu = settingsLoader.item
    if (!menu) return
    if (panelLoader.item && panelLoader.item.opened) panelLoader.item.close()
    menu.open()
  }

  function closeSettings() {
    if (settingsLoader.item && settingsLoader.item.close) settingsLoader.item.close()
  }

  function toggleSettings() {
    if (settingsOpen) closeSettings()
    else openSettings()
  }

  // Persist one option into this widget's shell.json layout entry, locally
  // first so the bar and the popup redraw on the click itself.
  function setOption(name, value) {
    // Keep at least one of the two bar readings on, or the pill would have
    // nothing to show and no way back from the bar.
    if (name === "showIcon" && value === false && !showTemperature) return
    if (name === "showTemperature" && value === false && !showIcon) return

    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    entry[name] = value

    root.settings = entry
    if (panelLoader.item && "settings" in panelLoader.item) panelLoader.item.settings = entry
    if (settingsLoader.item && "settings" in settingsLoader.item) settingsLoader.item.settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function option(name, fallback) {
    return setting(name, fallback)
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: (panelLoader.item && panelLoader.item.popoutSwitchClosing === true)
    || (settingsLoader.item && settingsLoader.item.popoutSwitchClosing === true)

  function closeForPopoutSwitch() {
    if (settingsLoader.item && settingsLoader.item.closeForPopoutSwitch) settingsLoader.item.closeForPopoutSwitch()
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  // ---- bar pill ---------------------------------------------------------

  // The panel resolves the current conditions (the fast open-meteo reading
  // first, wttr.in as fallback). Show the condition icon and that temperature;
  // leave the temperature out in a vertical bar where a label would not fit.
  readonly property bool showIcon: setting("showIcon", true) !== false
  readonly property bool showTemperature: setting("showTemperature", true) !== false
  readonly property bool iconVisible: root.showIcon && panelLoader.item !== null && panelLoader.item.label !== ""
  readonly property string temperatureText: {
    if (!root.showTemperature || vertical) return ""
    var panel = panelLoader.item
    if (!panel || !panel.reportTempNum) return ""
    return panel.reportTempNum + panel.tempUnit
  }

  function handlePress(button) {
    if (!root.bar) return
    if (button === Qt.RightButton) root.toggleSettings()
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

  visible: root.iconVisible || root.temperatureText !== ""
  implicitWidth: (root.iconVisible ? button.implicitWidth : 0)
    + (temperatureLabel.visible ? Style.space(2) + temperatureLabel.implicitWidth : 0)
  implicitHeight: button.implicitHeight

  onBarChanged: {
    injectPanel()
    injectSettings()
  }
  onSettingsChanged: {
    injectPanel()
    injectSettings()
  }

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

  // Built on first right click: the settings menu is not needed at startup.
  Loader {
    id: settingsLoader
    active: false
    source: Qt.resolvedUrl("SettingsMenu.qml")
    visible: false
    onLoaded: {
      root.injectSettings()
      Qt.callLater(root.injectSettings)
    }
  }

  BarIconButton {
    id: button
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    bar: root.bar
    visible: root.iconVisible
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
    anchors.left: root.iconVisible ? button.right : parent.left
    anchors.leftMargin: root.iconVisible ? Style.space(2) : 0
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
  // widget's right-click (settings) and middle-click (refresh) shortcuts
  // working across the label too.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton | Qt.MiddleButton
    onClicked: function(mouse) {
      root.handlePress(mouse.button)
    }
  }
}
