pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.background.widgets.clock
import QtQuick
import QtQuick.Layouts

/**
 * Big digital clock shown on the lock screen.
 * Styled after the desktop digital clock widget: reuses its font
 * configuration, text shadow and smooth time change animations.
 */
ColumnLayout {
    id: root

    // Centered on the lock surface by default; override via anchors at instantiation
    anchors.centerIn: parent

    readonly property var fontConfig: Config.options.background.widgets.clock.digital.font
    readonly property color colText: Appearance.colors.colOnSecondaryContainer

    // Fade-in animation, same style as the lock toolbars
    property real clockOpacity: 0
    Behavior on clockOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Component.onCompleted: clockOpacity = 1

    opacity: root.clockOpacity
    spacing: 10

    ClockText {
        id: timeText
        Layout.alignment: Qt.AlignHCenter
        text: DateTime.time
        color: root.colText
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: root.fontConfig.size
            weight: root.fontConfig.weight
            family: root.fontConfig.family
            variableAxes: ({
                    "wdth": root.fontConfig.width,
                    "ROND": root.fontConfig.roundness
                })
        }
    }

    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.alignment: Qt.AlignHCenter
        text: DateTime.longDate
        color: root.colText
        horizontalAlignment: Text.AlignHCenter
    }
}
