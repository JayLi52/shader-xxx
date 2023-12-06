#define EPSILON 0.001
#define MAX_DIST 200.

vec2 fixUV(vec2 uv) {
    return (2. * uv - iResolution.xy) / iResolution.x;
}

float ground(vec2 p) {
    return sin(p.x) * sin(p.y);
}

float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.;
    for (int i = 0; i < 128; i++) {
        vec3 p = ro + t * rd;
        float h = p.y - ground(p.xz);
        if (abs(h) < EPSILON || t > MAX_DIST)
            break;
        t += h;
    }
    return t;
}

vec3 calcNorm(vec3 p) {
    vec2 epsilon = vec2(1e-5, 0);
    return normalize(vec3(
        ground(p.xz + epsilon.xy) - ground(p.xz - epsilon.xy),
        2.0 * epsilon.x,
        ground(p.xz + epsilon.yx) - ground(p.xz - epsilon.yx)
    ));
}

mat3 setCamera(vec3 ro, vec3 target, float cr) {
    vec3 z = normalize(target - ro);
    vec3 up = normalize(vec3(sin(cr), cos(cr), 0));
    vec3 x = cross(z, up);
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 render(vec2 uv) {
    vec3 col = vec3(0);

    float an = 0.2 * iTime;
    float r = 10.;
    vec3 ro = vec3(r * sin(an), 5, r * cos(an));
    vec3 target = vec3(0, 0, 0);
    mat3 cam = setCamera(ro, target, 0.);

    float fl = 1.;
    vec3 rd = normalize(cam * vec3(uv, fl));

    float t = rayMarch(ro, rd);

    if (t < MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 n = calcNorm(p);
        vec3 difColor = vec3(0.9, 0.8, 0.);
        col = difColor * dot(n, vec3(0, 1, 0));
    }

    return sqrt(col);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fixUV(fragCoord);
    vec3 col = render(uv);
    fragColor = vec4(col, 1.);
}