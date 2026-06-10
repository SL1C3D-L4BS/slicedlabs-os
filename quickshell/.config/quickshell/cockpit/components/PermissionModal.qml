// SlicedLabs · body · © 2026 SlicedLabs
import QtQuick
import "../generated"

// PermissionModal — the human-in-the-loop gate: show WHAT will run and its
// SCOPE, then Deny / Approve. The UI of every agentic effect (hermes → sl-sandbox
// → Warden record_action). Drop inside a ModalShell whose title says who's asking.
Column {
    id: perm
    property string summary: ""    // the one-line "what"
    property string detail: ""     // the command / payload (mono block)
    property string scope: ""      // e.g. "sandbox: read-only · ~/SlicedLabs"
    signal approved()
    signal denied()

    width: parent ? parent.width : Theme.modalWidth
    spacing: Theme.modalGap

    Text {
        visible: perm.summary.length > 0
        width: parent.width
        text: perm.summary
        color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.uiSize
        wrapMode: Text.WordWrap
    }

    Rectangle {
        visible: perm.detail.length > 0
        width: parent.width
        implicitHeight: dt.implicitHeight + Theme.gap * 2
        radius: Theme.radiusSm
        color: Qt.rgba(0, 0, 0, 0.22)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, Theme.modalHairline)
        Text {
            id: dt
            anchors.fill: parent
            anchors.margins: Theme.gap
            text: perm.detail
            color: Theme.semTextInfo; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
            wrapMode: Text.WrapAnywhere
        }
    }

    Text {
        visible: perm.scope.length > 0
        width: parent.width
        text: perm.scope
        color: Theme.semTextTertiary; font.family: Theme.mono; font.pixelSize: Theme.uiSizeSm
    }

    Row {
        anchors.right: parent.right
        spacing: Theme.gap
        Rectangle {
            width: dn.implicitWidth + Theme.padX * 2; height: 34; radius: Theme.radius
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, dnm.containsMouse ? 0.28 : 0.16)
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            Text { id: dn; anchors.centerIn: parent; text: "Deny"; color: Theme.error; font.family: Theme.mono; font.pixelSize: Theme.uiSize }
            MouseArea { id: dnm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: perm.denied() }
        }
        Rectangle {
            width: ap.implicitWidth + Theme.padX * 2; height: 34; radius: Theme.radius
            color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, apm.containsMouse ? 0.34 : 0.20)
            Behavior on color { ColorAnimation { duration: Theme.quickMs } }
            Text { id: ap; anchors.centerIn: parent; text: "Approve"; color: Theme.success; font.family: Theme.mono; font.pixelSize: Theme.uiSize; font.weight: Theme.weightActive }
            MouseArea { id: apm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: perm.approved() }
        }
    }
}
