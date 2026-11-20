import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// Right-click menu for the weather pill: what the bar and the popup show, how
// many forecast days the popup carries, and which place it reports for. Widget
// options live in the widget's shell.json layout entry and are written back by
// the host widget; the place is the shared weather.json state file, written
// through omarchy-weather-location.
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

  // ---- location ---------------------------------------------------------
  // The configured place is the shared weather.json state file, the same one
  // the panel watches. Empty means auto-detected (geo.omarchy.org).
  property var locationState: ({ name: "", latitude: null, longitude: null })
  readonly property bool autoLocation: Model.isAutoLocation(locationState)
  readonly property string locationName: String(locationState.name || "")

  property var suggestions: []
  property int suggestionIndex: 0
  property string pendingQuery: ""

  FileView {
    id: locationFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.locationState = Model.parseLocationFile(text())
    onLoadFailed: root.locationState = Model.parseLocationFile("")
  }

  Component.onCompleted: locationFile.reload()

  function useAutoLocation() {
    root.suggestions = []
    locationSaveProc.command = ["omarchy-weather-location", "--clear"]
    locationSaveProc.running = true
  }

  function chooseSuggestion(suggestion) {
    if (!suggestion) return
    root.suggestions = []
    locationSaveProc.command = ["omarchy-weather-location", "--set", String(suggestion.name),
      String(suggestion.latitude) + "," + String(suggestion.longitude)]
    locationSaveProc.running = true
  }

  function requestGeocode(text) {
    var query = String(text || "").trim()
    root.suggestionIndex = 0
    if (query.length < 2) {
      root.suggestions = []
      return
    }
    root.pendingQuery = query
    geocodeDebounce.restart()
  }

  function startGeocode() {
    if (geocodeProc.running) return
    geocodeProc.command = ["curl", "-fsS", "-A", "omarchy-weather/1.0", "--max-time", "5",
      "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(root.pendingQuery)
      + "&count=5&language=en&format=json"]
    geocodeProc.running = true
  }

  Timer {
    id: geocodeDebounce
    interval: 350
    onTriggered: root.startGeocode()
  }

  Process {
    id: geocodeProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.suggestions = Model.parseGeocodingResults(text)
    }
  }

  Process {
    id: locationSaveProc
  }

  // ---- menu -------------------------------------------------------------

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
    contentWidth: panel.fittedContentWidth(Style.space(420))
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

        PanelSeparator {
          foreground: root.foreground
        }

        PanelSectionHeader {
          text: strings.t("settings.currentReadings")
          foreground: root.foreground
          fontFamily: root.fontFamily
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
          label: strings.t("settings.showWind")
          description: strings.t("settings.showWindHint")
          checked: root.option("showWind", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showWind", !(root.option("showWind", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showHumidity")
          description: strings.t("settings.showHumidityHint")
          checked: root.option("showHumidity", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showHumidity", !(root.option("showHumidity", true) !== false))
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.showRain")
          description: strings.t("settings.showRainHint")
          checked: root.option("showRain", true) !== false
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.setOption("showRain", !(root.option("showRain", true) !== false))
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

        PanelSeparator {
          foreground: root.foreground
        }

        PanelSectionHeader {
          text: strings.t("settings.location")
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Toggle {
          width: parent.width
          label: strings.t("settings.locationAuto")
          description: strings.t("settings.locationAutoHint")
          checked: root.autoLocation
          foreground: root.foreground
          fontFamily: root.fontFamily
          // Turning it on clears the stored place; turning it off is done by
          // picking a city below, so a click while on is a no-op.
          onClicked: if (!root.autoLocation) root.useAutoLocation()
        }

        Text {
          width: parent.width
          visible: !root.autoLocation && root.locationName !== ""
          textFormat: Text.PlainText
          elide: Text.ElideRight
          text: strings.t("settings.locationCurrent").arg(root.locationName)
          color: Qt.darker(root.foreground, 1.35)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        TextField {
          id: locationField
          width: parent.width
          placeholderText: strings.t("settings.locationSearch")
          foreground: root.foreground
          font.family: root.fontFamily
          onTextChanged: root.requestGeocode(text)
          onAccepted: root.chooseSuggestion(root.suggestions[Math.max(0, Math.min(root.suggestionIndex, root.suggestions.length - 1))])
        }

        Column {
          width: parent.width
          visible: root.suggestions.length > 0
          spacing: 0

          Repeater {
            model: root.suggestions

            Rectangle {
              required property var modelData
              required property int index
              width: parent.width
              height: suggestionRow.implicitHeight + Style.space(10)
              radius: Style.cornerRadius
              color: index === root.suggestionIndex
                ? Style.hoverFillFor(root.foreground, Commons.Color.accent) : "transparent"

              Row {
                id: suggestionRow
                anchors.left: parent.left
                anchors.leftMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(8)

                Text {
                  textFormat: Text.PlainText
                  text: modelData.name
                  color: index === root.suggestionIndex
                    ? Style.hoverStateColor(root.foreground, Commons.Color.accent) : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
                Text {
                  textFormat: Text.PlainText
                  visible: text !== ""
                  text: modelData.description
                  color: Qt.darker(root.foreground, 1.5)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: root.suggestionIndex = index
                onClicked: root.chooseSuggestion(modelData)
              }
            }
          }
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
