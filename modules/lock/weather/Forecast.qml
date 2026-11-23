import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.notch.pages.weather

StyledRect {
    id: root

    color: Hallownest.button
    radius: Tokens.rounding.extraLargeIncreased
    implicitHeight: header.anchors.margins + header.implicitHeight + Tokens.spacing.medium + layout.implicitHeight + layout.anchors.bottomMargin

    RowLayout {
        id: header

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.padding.largeIncreased

        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.topMargin: Math.round(fontInfo.pointSize * 0.12)
            text: "schedule"
            fontStyle: Tokens.font.icon.builders.medium.weight(title.font.weight).build()
        }

        StyledText {
            id: title

            text: Tr.tr("Hourly forecast")
            font: Tokens.font.title.medium
        }
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.largeIncreased
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.small

        Repeater {
            model: CUtils.clamp(Math.floor((layout.width + layout.spacing) / (Tokens.sizes.lock.forecastItemWidth + layout.spacing)), 0, Weather.hourlyForecast.length)

            ColumnLayout {
                id: hour

                required property int index
                readonly property var cond: Weather.hourlyForecast[index]

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                MaterialShape {
                    Layout.alignment: Qt.AlignHCenter
                    implicitSize: temp.implicitHeight + Tokens.padding.medium * 2
                    shape: MaterialShape.Cookie4Sided
                    color: Qt.alpha(Hallownest.soul, hour.index === 0 ? 0.14 : 0)

                    Behavior on color {
                        CAnim {}
                    }

                    StyledText {
                        id: temp

                        anchors.centerIn: parent
                        text: Weather.formatTemp(hour.cond.tempC, true)
                        color: hour.index === 0 ? Hallownest.soul : Hallownest.text
                        font: Tokens.font.title.medium
                    }
                }

                WeatherIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: hour.cond.icon
                    colour: Hallownest.soul
                    size: 34
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Strings.percent(hour.cond.precipChance)
                    color: Hallownest.lifeblood
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.extraSmall
                    Layout.alignment: Qt.AlignHCenter
                    text: hour.index === 0 ? Tr.trCtx("Now", "forecast column") : Qt.formatDateTime(new Date(hour.cond.timestamp.replace("T", " ")), Units.twelveHourClock ? "ha" : "hh:00")
                    color: Hallownest.subtext
                    font: Tokens.font.body.medium
                }
            }
        }
    }
}
