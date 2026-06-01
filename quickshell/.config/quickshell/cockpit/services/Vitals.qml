pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Vitals — native cpu/mem/temp sampling (replaces the guarded monitoring chips
// for the always-on right pill + feeds the Reactor's turbulence/temperature).
Singleton {
    id: root
    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property int gpu: 0
    property real frameMs: 0
    readonly property real cpuFrac: cpu / 100.0
    readonly property real tempFrac: Math.max(0, Math.min(1, (temp - 40) / 50.0))

    Process {
        id: p
        command: ["bash", "-c",
            "a=($(grep '^cpu ' /proc/stat)); t1=0; for v in \"${a[@]:1}\"; do t1=$((t1+v)); done; i1=${a[4]};" +
            "sleep 0.25;" +
            "b=($(grep '^cpu ' /proc/stat)); t2=0; for v in \"${b[@]:1}\"; do t2=$((t2+v)); done; i2=${b[4]};" +
            "dt=$((t2-t1)); di=$((i2-i1)); c=0; [ $dt -gt 0 ] && c=$((100*(dt-di)/dt));" +
            "mt=$(awk '/MemTotal/{print $2}' /proc/meminfo); ma=$(awk '/MemAvailable/{print $2}' /proc/meminfo); m=$((100*(mt-ma)/mt));" +
            "tp=0; for z in /sys/class/thermal/thermal_zone*/temp; do r=$(cat \"$z\" 2>/dev/null || echo 0); if [ \"$r\" -gt 0 ]; then tp=$((r/1000)); break; fi; done;" +
            "g=0; for f in /sys/class/drm/card*/device/gpu_busy_percent; do r=$(cat \"$f\" 2>/dev/null || echo 0); if [ \"$r\" -gt 0 ]; then g=$r; break; fi; done;" +
            "printf '{\"cpu\":%d,\"mem\":%d,\"temp\":%d,\"gpu\":%d}' $c $m $tp $g"]
        stdout: StdioCollector {
            id: vc
            onStreamFinished: {
                try { var j = JSON.parse(vc.text); root.cpu = j.cpu; root.mem = j.mem; root.temp = j.temp; root.gpu = j.gpu } catch (e) {}
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!p.running) p.running = true }

    // frame-time — EMA of the compositor frame interval. The living Reactor already
    // renders continuously, so sampling is ~free. ~33ms at 30Hz; rises if frames drop
    // (the visible regression signal behind guarantee #2).
    FrameAnimation {
        running: true
        onTriggered: root.frameMs = root.frameMs <= 0 ? frameTime * 1000
                                                       : root.frameMs * 0.9 + frameTime * 1000 * 0.1
    }
}
