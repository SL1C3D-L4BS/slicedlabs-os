// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"

// InputBar — the modal prompt / search field. Emits submitted(text) on Enter;
// focus ring rides the info border. Mirrors the keys-browser filter input.
Rectangle {
    id: bar
    property alias text: input.text
    property string placeholder: ""
    property bool submitOnEnter: true
    signal submitted(string text)

    width: parent ? parent.width : Theme.modalWidth
    height: Theme.modalInputHeight
    radius: Theme.radius
    color: Qt.rgba(1, 1, 1, Theme.modalFillSubtle)
    border.width: 1
    border.color: input.activeFocus ? Theme.semBorderInfo : Qt.rgba(1, 1, 1, Theme.modalHairline)
    Behavior on border.color { ColorAnimation { duration: Theme.quickMs } }

    function focusInput() { input.forceActiveFocus() }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.padX
        anchors.rightMargin: Theme.padX
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.mono
        font.pixelSize: Theme.uiSize
        clip: true
        selectByMouse: true
        onAccepted: if (bar.submitOnEnter) bar.submitted(text)
    }
    Text {
        visible: input.text.length === 0
        anchors.left: parent.left
        anchors.leftMargin: Theme.padX
        anchors.verticalCenter: parent.verticalCenter
        text: bar.placeholder
        color: Theme.fgMuted
        font.family: Theme.mono
        font.pixelSize: Theme.uiSize
    }
}
