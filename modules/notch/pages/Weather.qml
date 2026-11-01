pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.notch
import qs.modules.notch.pages.weather

NotchPage {
    id: root

    implicitWidth: 620
    implicitHeight: layout.implicitHeight

    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.large

            HoverHandler {
                id: mainHover
            }

            WeatherIcon {
                icon: Weather.icon
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                colour: Hallownest.soul
                animate: true
                active: mainHover.hovered
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Weather.temp
                    font: Tokens.font.body.builders.large.size(36).weight(Font.Medium).build()
                    color: Hallownest.lifeblood
                }

                StyledText {
                    text: Weather.description
                    font: Tokens.font.body.medium
                    color: Hallownest.subtext
                }

                StyledText {
                    text: Weather.city || Tr.tr("Loading...")
                    font: Tokens.font.label.medium
                    color: Hallownest.faint
                }
            }

            Item {
                Layout.fillWidth: true
            }

            GridLayout {
                columns: 2
                rowSpacing: Tokens.spacing.small
                columnSpacing: Tokens.spacing.large

                Stat {
                    icon: "thermostat"
                    value: Weather.feelsLike
                    colour: Hallownest.lifeblood
                }

                Stat {
                    icon: "water_drop"
                    value: Strings.percent(Weather.humidity)
                    colour: Hallownest.crystal
                }

                Stat {
                    icon: "air"
                    value: Weather.windSpeed ? Tr.tr("%1 km/h").arg(Weather.windSpeed) : "--"
                    colour: Hallownest.gold
                }

                Stat {
                    icon: "wb_twilight"
                    value: `${Weather.sunrise} – ${Weather.sunset}`
                    colour: Hallownest.gold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: Weather.forecast

                StyledRect {
                    id: day

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: dayColumn.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.large
                    color: Hallownest.card

                    HoverHandler {
                        id: dayHover
                    }

                    ColumnLayout {
                        id: dayColumn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: day.index === 0 ? Tr.trCtx("Today", "forecast column") : new Date(day.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: Tokens.font.label.medium
                            color: Hallownest.lifeblood
                        }

                        WeatherIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: day.modelData.icon
                            colour: Hallownest.soul
                            active: dayHover.hovered
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: `${Weather.formatTemp(day.modelData.maxTempC, true)} ${Weather.formatTemp(day.modelData.minTempC, true)}`
                            font: Tokens.font.label.small
                            color: Hallownest.subtext
                        }
                    }
                }
            }
        }
    }

    component Stat: Row {
        id: stat

        property string icon
        property string value
        property color colour

        spacing: Tokens.spacing.small

        WeatherIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: stat.icon
            colour: stat.colour
            size: 20
            glow: false
        }

        StyledText {
            color: Hallownest.text
            anchors.verticalCenter: parent.verticalCenter
            text: stat.value
            font: Tokens.font.body.small
        }
    }
}
