#define EPSILON 0.001
#define MAX_DIST 200.
#define MAX_ITER 128

vec2 fixUV(vec2 uv) {
    return (2. * uv - iResolution.xy) / iResolution.x;
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float random(vec2 pos) {
    // return abs(fract(78523.215 * sin(dot(pos, vec2(25.32, 547.23)))));
    return hash12(pos);
}

vec3 noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    vec2 u = f * f * (3.0 - 2.0 * f);
    vec2 du = 6. * u * (1. - u);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    return vec3(a + (b - a) * u.x * (1. - u.y) +
        (c - a) * (1. - u.x) * u.y +
        (d - a) * u.x * u.y, 
        du * (vec2(b - a, c - a) +
        (a - b - c + d) * u.yx));
}

mat2 mat = mat2(0.6, -0.8, 0.8, 0.6);

float ground(vec2 p) {
    float a = 0.;
    float b = 1.;
    vec2 d = vec2(0);

    for (int i = 0; i < 10; i++) {
        vec3 n = noise(p);
        d += n.yz;
        a += b * n.x / (1. + dot(d, d));
        p = mat * p * 2.;
        b *= 0.5;
    }

    return a;
}

float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.;
    for(int i = 0; i < MAX_ITER; i++) {
        vec3 p = ro + t * rd;
        float h = p.y - ground(p.xz);
        if(abs(h) < EPSILON * t || t > MAX_DIST)
            break;
        t += 0.2 * h;
    }
    return t;
}

vec3 calcNorm(vec3 p) {
    vec2 epsilon = vec2(1e-5, 0);
    return normalize(vec3(ground(p.xz + epsilon.xy) - ground(p.xz - epsilon.xy), 2.0 * epsilon.x, ground(p.xz + epsilon.yx) - ground(p.xz - epsilon.yx)));
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

    float an = sin(iTime * .2) * .2 + .4;
    float r = 3.1;
    vec3 ro = vec3(r * sin(an), 1., r * cos(an));
    vec3 target = vec3(0, 0., 0);
    mat3 cam = setCamera(ro, target, 0.);

    float fl = 1.;
    vec3 rd = normalize(cam * vec3(uv, fl));

    float t = rayMarch(ro, rd);

    if(t < MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 n = calcNorm(p);
        vec3 difColor = vec3(0.67, 0.57, 0.44);
        col = difColor * dot(n, vec3(0, 1, 0));
    }

    return sqrt(col);
    // return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fixUV(fragCoord);
    vec3 col = render(uv);
    fragColor = vec4(col, 1.);
}