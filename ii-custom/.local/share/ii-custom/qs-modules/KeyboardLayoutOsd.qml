pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Centered on-screen indicator shown briefly when the keyboard layout changes.
 * Displays the layout code (e.g. RU) and the language name (e.g. Русский)
 * in a semi-transparent square, styled after the other OSD panels.
 */
Scope {
    id: root

    property bool windowVisible: false
    property real targetOpacity: 0
    // Guard against showing on shell (re)start: the first code is eaten silently
    property string lastLayoutCode: ""

    readonly property string layoutName: HyprlandXkb.currentLayoutName ?? ""
    readonly property string layoutCode: HyprlandXkb.currentLayoutCode ?? ""
    readonly property string displayCode: layoutCode.split(":")[0].split("-")[0].toUpperCase().slice(0, 4)
    readonly property string displayLanguage: languageNames[displayCode.toLowerCase()] ?? layoutName
    property var focusedScreen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor?.name ?? ""))

    // Native names for common layout codes; fallback is Hyprland's layout name
    readonly property var languageNames: ({
            "ru": "Русский",
            "us": "English",
            "en": "English",
            "uk": "Українська",
            "by": "Беларуская",
            "be": "Беларуская",
            "de": "Deutsch",
            "fr": "Français",
            "es": "Español",
            "it": "Italiano",
            "pl": "Polski",
            "pt": "Português",
            "cz": "Čeština",
            "jp": "日本語",
            "cn": "中文",
            "zh": "中文",
            "ko": "한국어",
        })

    function showOsd() {
        if (GlobalStates.screenLocked)
            return;
        root.windowVisible = true;
        root.targetOpacity = 1;
        fadeOutTimer.restart();
        hideWindowTimer.restart();
    }

    Connections {
        target: HyprlandXkb
        function onCurrentLayoutCodeChanged() {
            const code = root.layoutCode;
            if (!code)
                return;
            if (!root.lastLayoutCode) {
                // First value after (re)start, don't show the indicator
                root.lastLayoutCode = code;
                return;
            }
            if (code === root.lastLayoutCode)
                return;
            root.lastLayoutCode = code;
            root.showOsd();
        }
    }

    Timer {
        id: fadeOutTimer
        interval: 800
        repeat: false
        running: false
        onTriggered: root.targetOpacity = 0
    }

    Timer {
        id: hideWindowTimer
        // Full display interval + fade-out duration, then free the layer
        interval: fadeOutTimer.interval + Appearance.animation.elementMoveFast.duration + 100
        repeat: false
        running: false
        onTriggered: root.windowVisible = false
    }

    Loader {
        id: osdLoader
        active: root.windowVisible

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"
            // Square side adapts to content, with a minimum
            readonly property int squareSide: Math.max(140, codeText.implicitWidth + 48, languageText.implicitWidth + 48)
            WlrLayershell.namespace: "quickshell:keyboardLayoutOsd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            // Empty input region: clicks pass through the whole window
            mask: Region {
            }
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            visible: true

            Component.onCompleted: {
                if (root.focusedScreen)
                    osdRoot.screen = root.focusedScreen;
            }
            Connections {
                target: root
                function onFocusedScreenChanged() {
                    if (root.focusedScreen)
                        osdRoot.screen = root.focusedScreen;
                }
            }

            Item {
                id: contentRoot
                anchors.fill: parent
                opacity: root.targetOpacity
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                StyledRectangularShadow {
                    target: osdSquare
                }
                Rectangle {
                    id: osdSquare
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: -50
                        bottom: parent.bottom
                        bottomMargin: 90
                    }
                    width: osdRoot.squareSide
                    height: osdRoot.squareSide
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        StyledText {
                            id: codeText
                            text: root.displayCode
                            font.pixelSize: 46
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }

                        StyledText {
                            id: languageText
                            text: root.displayLanguage
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.8
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
