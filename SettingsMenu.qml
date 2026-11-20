import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Right-click menu for the weather pill: what the bar and the popup show, and
// how many forecast days the popup carries. Values live in the widget's
// shell.json layout entry and are written back by the host widget.
Panel {
  id: root
  moduleName: "io.github.jotenakis2.myweather"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property color foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family

  function option(name, fallback) {
    return root.hostWidget ? root.hostWidget.option(name, fallback) : fallback
  }

  function setOption(name, value) {
    if (root.hostWidget) root.hostWidget.setOption(name, value)
  }

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  function dayOptions() {
    var out = [{ value: "0", label: strings.t("settings.forecastNone") }]
    for (var n = 1; n <= 7; ++n)
      out.push({ value: String(n), label: strings.tn("settings.forecastDayCount", n).arg(n) })
    return out
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget
    bar: root.bar
    open: root.opened
    centerOnBar: false
    // Same offset as the data panel, so the two line up when switching.
    gap: Style.gapsOut + 5
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: keyCatcher
      implicitHeight: menuColumn.implicitHeight
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: menuColumn
        width: parent.width
        spacing: Style.space(8)

        PanelSectionHeader {
          text: strings.t("settings.title")
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showTemperature")
          description: strings.t("settings.showTemperatureHint")
          checked: root.option("showTemperature", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showTemperature", !(root.option("showTemperature", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showIcon")
          description: strings.t("settings.showIconHint")
          checked: root.option("showIcon", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showIcon", !(root.option("showIcon", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showFeelsLike")
          description: strings.t("settings.showFeelsLikeHint")
          checked: root.option("showFeelsLike", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showFeelsLike", !(root.option("showFeelsLike", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showLocation")
          description: strings.t("settings.showLocationHint")
          checked: root.option("showLocation", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showLocation", !(root.option("showLocation", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showUpdatedAt")
          description: strings.t("settings.showUpdatedAtHint")
          checked: root.option("showUpdatedAt", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showUpdatedAt", !(root.option("showUpdatedAt", true) !== false))
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Dropdown {
          width: parent.width
          label: strings.t("settings.forecastDays")
          value: String(root.option("forecastDays", 5))
          options: root.dayOptions()
          foreground: root.foreground
          fontFamily: root.fontFamily
          onChanged: function(value) { root.setOption("forecastDays", parseInt(value, 10)) }
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          text: strings.t("settings.keepOne")
          color: Qt.darker(root.foreground, 1.5)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
