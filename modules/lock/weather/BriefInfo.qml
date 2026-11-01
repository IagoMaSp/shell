import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.notch.pages.weather

ColumnLayout {
    id: root

    required property int rootHeight

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: Weather.description
        color: Hallownest.subtext
        font: Tokens.font.body.large
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        StyledText {
            id: temp

            animate: true
            text: Weather.temp
            color: Hallownest.lifeblood
            font.family: Hallownest.serif
            font.pointSize: Tokens.font.headline.large.pointSize * 1.4
            font.weight: Font.Bold
        }

        WeatherIcon {
            icon: Weather.icon
            colour: Hallownest.soul
            size: 64
            ambient: true
        }
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        // TRANSLATORS: %1 = apparent temperature, unit already included
        text: Tr.tr("Feels like %1").arg(Weather.temp)
        color: Hallownest.subtext
        font: Tokens.font.body.large
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: {
            const today = Weather.forecast[0];
            // TRANSLATORS: %1/%2 = today's max and min temperature, units already included
            return Tr.tr("High %1 • Low %2").arg(Weather.formatTemp(today?.maxTempC)).arg(Weather.formatTemp(today?.minTempC));
        }
        color: Hallownest.subtext
        font: Tokens.font.body.medium
    }
}
