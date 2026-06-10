#version 440
// glass.frag — the Cockpit's Liquid Glass material. Procedural specular / Fresnel
// rim / chromatic + edge lensing of the CURRENT wallpaper, composited OVER niri's
// real dual-kawase blur (xray) that already sits behind the layer-shell surface.
// A layer-shell surface can't sample live windows, so we lens the wallpaper
// texture (~/.cache/engine-backdrop.png) and let niri supply the live blur. RX-580
// budgeted: edge-only wallpaper reveal, quality tiers, motion gate.
//
// Grounded: RealTimeRendering §9.5 (Fresnel rim at grazing angles), TheBookofShaders
// §3.3 (rounded-rect SDF) / §3.1.1 (smoothstep edges). Uniforms mirror Glass.qml.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;     // built-in (required first)
    float qt_Opacity;    // built-in
    float time;          // seconds
    vec2  rectSize;      // surface size in px
    float radius;        // corner radius px
    float refraction;    // edge lensing px
    float rimWidth;      // Fresnel rim px
    float rimOpacity;
    float specIntensity;
    float specSpeed;
    float chromatic;     // R/B aberration px
    float ambientBleed;
    float quality;       // 1 high · 0.5 low · 0 off
    float reduceMotion;  // 0/1
    float rimBrandMix;   // v3: rim light picks up the brand hue (0 = pure white)
    vec4  tint;          // frosted fill rgba
    vec4  brand;         // ambient bleed hue
    vec4  wallRect;      // (x,y,w,h) of this surface in wallpaper UV
};

layout(binding = 1) uniform sampler2D wallpaper;

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// signed distance to a rounded rectangle — TheBookofShaders §3.3 idiom
float sdRound(vec2 p, vec2 b, float r){
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main(){
    if (rectSize.x < 1.0 || rectSize.y < 1.0) { fragColor = vec4(0.0); return; }

    vec2 px = qt_TexCoord0 * rectSize;
    vec2 c  = rectSize * 0.5;
    float r = min(radius, min(c.x, c.y));
    float d = sdRound(px - c, c, r);            // <0 inside
    float aa = 1.0;
    float cov = 1.0 - smoothstep(-aa, aa, d);   // surface coverage (AA edge)
    if (cov <= 0.0) { fragColor = vec4(0.0); return; }

    // OFF → flat frosted (== today's cssChip)
    if (quality < 0.25) {
        fragColor = vec4(tint.rgb, cov * tint.a) * qt_Opacity;
        return;
    }

    float depth = clamp(-d / max(r, 12.0), 0.0, 1.0); // 0 at edge → 1 deep inside
    float edge  = 1.0 - depth;                         // concentrate lensing/rim at edge
    vec2  dir   = (length(px - c) > 0.001) ? normalize((px - c) / c) : vec2(0.0);

    vec3 frost = tint.rgb;
    vec3 col   = frost;

    // HIGH → lens (refract) the wallpaper inward at the rim, with chromatic split
    if (quality >= 0.75) {
        vec2 wuv = wallRect.xy + qt_TexCoord0 * wallRect.zw;
        vec2 off = dir * (refraction / rectSize) * wallRect.zw * edge;
        vec2 cao = dir * (chromatic  / rectSize) * wallRect.zw * edge;
        vec3 lensed;
        lensed.r = texture(wallpaper, wuv + off + cao).r;
        lensed.g = texture(wallpaper, wuv + off      ).g;
        lensed.b = texture(wallpaper, wuv + off - cao).b;
        col = mix(frost, lensed, edge * 0.55);
    }

    // ambient brand-hue bleed through the body
    col = mix(col, brand.rgb, ambientBleed * depth);

    // top sheen — soft fixed highlight near the upper edge (light from above).
    float sheen = smoothstep(0.50, 0.0, qt_TexCoord0.y);
    float spec  = sheen * specIntensity * (0.25 + 0.35 * edge);
    // liquid sweep — a slow diagonal specular band on FOCAL surfaces (specSpeed>0),
    // killed by reduceMotion. Multiplied by `edge` so it lives at the rim and never
    // washes out the centre where text sits (the contrast_floor discipline).
    if (specSpeed > 0.001 && reduceMotion < 0.5) {
        float phase = (qt_TexCoord0.x + qt_TexCoord0.y) * 2.2 - time * specSpeed;
        float band  = smoothstep(0.55, 1.0, sin(phase) * 0.5 + 0.5);
        spec += band * specIntensity * 0.6 * edge;
    }
    col += spec;

    // Fresnel rim — thin grazing-edge light, brand-tinted per rimBrandMix (v3)
    float rim = 1.0 - smoothstep(0.0, max(rimWidth, 0.5), abs(d));
    col += rim * rimOpacity * mix(vec3(1.0), brand.rgb, rimBrandMix);

    // anti-banding dither
    col += (hash(px) - 0.5) * 0.02;

    float alpha = cov * max(tint.a, rim * rimOpacity);
    fragColor = vec4(col, alpha) * qt_Opacity;
}
