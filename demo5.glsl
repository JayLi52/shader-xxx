#define C 0.707107

float noise(vec2 x) {
    return abs(fract(114514.114514 * sin(dot(x, vec2(123., 456.)))));
}

float line(vec2 p, float dir) {
    float d = dot(p, dir > 0.5 ? vec2(C, C) : vec2(-C, C));
    return smoothstep(.0, .05, abs(d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = 15. * 2. * (fragCoord - .5 * iResolution.xy) / iResolution.y;
    uv += iTime / 5.;
    vec3 col = vec3(line(fract(uv) - .5, noise(floor(uv))));
    fragColor = vec4(col, 1.);
}