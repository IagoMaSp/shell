pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    required property real centerScale

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    StyledText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        color: Hallownest.soul
        font.family: Hallownest.serif
        font.pointSize: Tokens.font.headline.large.pointSize * 6 * root.centerScale
        font.weight: Font.Bold
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Hallownest.soul
            shadowOpacity: 0.35
            shadowBlur: 1
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 32
        }

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    StyledText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)

        text: Time.minuteStr
        color: Hallownest.steel
        font.family: Hallownest.serif
        font.pointSize: Tokens.font.headline.large.pointSize * (Units.twelveHourClock ? 3.3 : 6) * root.centerScale
        font.weight: Font.Bold

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }

    Loader {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: hourMetrics.tightBoundingRect.height - implicitHeight

        active: Units.twelveHourClock
        asynchronous: true

        sourceComponent: StyledRect {
            color: Hallownest.card
            radius: Tokens.rounding.large

            implicitWidth: minuteMetrics.tightBoundingRect.width
            implicitHeight: amPmMetrics.tightBoundingRect.height + Tokens.padding.large * 2

            StyledText {
                id: amPm

                anchors.centerIn: parent
                width: amPmMetrics.tightBoundingRect.width
                height: amPmMetrics.tightBoundingRect.height
                transform: Translate {
                    x: -amPmMetrics.tightBoundingRect.x
                    y: -root.calcTopOff(amPmMetrics)
                }

                text: Time.amPmStr
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: Tokens.font.headline.small.pointSize * 2 * root.centerScale

                TextMetrics {
                    id: amPmMetrics

                    text: amPm.text
                    font: amPm.font
                }
            }
        }
    }
}
