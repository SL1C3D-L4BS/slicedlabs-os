import QtQuick
import "../generated"
import "../services"

// Reactor — the living core. A brand-hued fragment-shader organism that breathes
// (idle), turbulates with CPU/build, warm-shifts with temperature, reacts to
// audio (Cava), and tints on build state. Alive but disciplined: continuous
// motion here is the signal; the periphery stays still.
Item {
    id: reactor
    property string tab: Niri.focused
    readonly property color brand: Theme.brand(tab)
    readonly property real turbulence: Math.min(1.0, Vitals.cpuFrac + (Build.building ? 0.45 : 0))
    readonly property real temperature: Vitals.tempFrac
    readonly property real level: Cava.level
    // 0 idle · 1 build · 2 success · 3 error · 4 stream · 5 game
    readonly property int reactorState:
        Build.fail ? 3 : Build.building ? 1 : (tab === "streaming" ? 4 : tab === "gaming" ? 5 : 0)

    implicitWidth: Theme.barHeight - 8
    implicitHeight: Theme.barHeight - 8

    ShaderEffect {
        id: fx
        anchors.fill: parent
        property real time: 0
        property color brandColor: reactor.brand
        property real turbulence: reactor.turbulence
        property real temperature: reactor.temperature
        property real level: reactor.level
        property real state: reactor.reactorState
        fragmentShader: Qt.resolvedUrl("shaders/reactor.frag.qsb")

        Behavior on turbulence { NumberAnimation { duration: Theme.slowMs } }
        Behavior on temperature { NumberAnimation { duration: Theme.slowMs } }
        Behavior on brandColor { ColorAnimation { duration: Theme.slowMs } }

        FrameAnimation { running: fx.visible; onTriggered: fx.time += frameTime }
    }
}
