#version 440
// reactor.frag — the Cockpit's living core. A brand-hued SDF/plasma organism
// that breathes (idle), turbulates (build), tints green/red (success/error) and
// shows an audio/frame ring (stream/game). Procedural — no backdrop sampler
// (a layer-shell surface can't read the compositor backdrop; Niri supplies the
// frosted blur behind the pill). Authored portable to the engine shader pipeline.
//
// Uniform names/types mirror QML properties on the Reactor ShaderEffect.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;     // built-in (required first)
    float qt_Opacity;   // built-in
    float time;         // seconds
    float turbulence;   // 0..1  (CPU load / build activity)
    float temperature;  // 0..1  (thermal warm-shift)
    float level;        // 0..1  (audio FFT / frametime)
    float state;        // 0 idle · 1 build · 2 success · 3 error · 4 stream · 5 game
    vec4 brandColor;    // active workspace identity (rgba)
};

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1, 0));
    float c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.02; a *= 0.5; }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;   // -1..1, centre origin
    float r = length(uv);
    float t = time;

    // turbulent displacement of the core edge (rises with build activity)
    float n = fbm(uv * 3.0 + vec2(t * 0.30, -t * 0.20));
    float disp = mix(0.03, 0.55, turbulence) * (n - 0.5);
    float core = 1.0 - smoothstep(0.0, 0.82 + disp, r);

    // breathing — the heartbeat (alive even at idle = signal)
    float breathe = 0.86 + 0.14 * sin(t * 1.15);
    core *= breathe;

    // audio / frametime ring
    float wob = 0.10 * sin(uv.x * 10.0 + t * 6.0) * level;
    float ring = level * (1.0 - smoothstep(0.015, 0.11, abs(r - 0.72 - wob)));

    // colour: brand, warm-shifted by temperature, state tints
    vec3 col = brandColor.rgb;
    col = mix(col, vec3(1.00, 0.55, 0.20), temperature * 0.5);            // heat
    if (state > 1.5 && state < 2.5) col = mix(col, vec3(0.78, 0.83, 0.17), 0.60); // success
    if (state > 2.5 && state < 3.5) col = mix(col, vec3(0.85, 0.36, 0.36), 0.70); // error
    col += vec3(0.16) * pow(core, 2.0);                                   // inner glow

    float alpha = clamp(core + ring, 0.0, 1.0);
    fragColor = vec4(col, alpha) * qt_Opacity;
}
