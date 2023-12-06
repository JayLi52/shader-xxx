#define RAYMARCH_TIME 128
#define PRECISION .001
#define AA 3
#define PI 3.14159265

vec2 fixUV(in vec2 c) {
    return (2. * c - iResolution.xy) / min(iResolution.x, iResolution.y);
}

float sdfSphere(in vec3 p) {
    return length(p) - 1.;
}

float sdfBox(in vec3 p, in vec3 r) {
    vec3 b = abs(p) - r;
    return length(max(b, 0.)) + min(max(max(b.x, b.y), b.z), 0.);
}

float shape1(in vec3 p) {
    // union
    float d = sdfSphere(p);
    d = min(d, sdfBox(p - vec3(0., 1., 0.), vec3(.4)));
    return d;
}

float shape2(in vec3 p) {
    // intersection
    float d = sdfSphere(p);
    d = max(d, sdfBox(p - vec3(0., 1., 0.), vec3(.4, 2., .4)));
    return d;
}

float shape3(in vec3 p) {
    // difference
    float d = sdfSphere(p);
    d = max(d, -1. * sdfBox(p, vec3(2., .4, .4)));
    return d;
}

vec2 opU(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

vec2 map(in vec3 p) {
    vec2 d = vec2(shape1(p - vec3(-2., 1., 0.)), 2.);
    d = opU(d, vec2(shape2(p - vec3(2., 1., 0.)), 3.));
    d = opU(d, vec2(shape3(p - vec3(0., 1., 2.)), 4.));
    return d;
}

vec2 rayMarch(in vec3 ro, in vec3 rd) {
    float t = 0.1;
    float tmax = 40.;
    vec2 res = vec2(-1.);
    if (rd.y < 0.) {
        float tp = -ro.y / rd.y;
        tmax = min(tmax, tp);
        res = vec2(tp, 1.);
    }
    for(int i = 0; i < RAYMARCH_TIME && t < tmax; i++) {
        vec3 p = ro + t * rd;
        vec2 d = map(p);
        if(d.x < PRECISION) {
            res = vec2(t, d.y);
            break;
        }
        t += d.x;
    }
    return res;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 p) {
    const float h = 0.0001;
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * map(p + k.xyy * h).x +
        k.yyx * map(p + k.yyx * h).x +
        k.yxy * map(p + k.yxy * h).x +
        k.xxx * map(p + k.xxx * h).x);
}

mat3 setCamera(vec3 ta, vec3 ro, float cr) {
    vec3 z = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.);
    vec3 x = normalize(cross(z, cp));
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

// https://iquilezles.org/articles/rmshadows
float softShadow(in vec3 ro, in vec3 rd, float k) {
    float res = 1.0;
    float ph = 1e20;
    float tmin = .1;
    float tmax = 10.;
    for(float t = tmin; t < tmax;) {
        float h = map(ro + rd * t).x;
        if(h < 0.001)
            return 0.0;
        float y = h * h / (2.0 * ph);
        float d = sqrt(h * h - y * y);
        res = min(res, k * d / max(0.0, t - y));
        ph = h;
        t += h;
    }
    return res;
}

// triangular signal
vec2 tri( in vec2 x )
{
    vec2 h = fract(x*.5)-.5;
    return 1.-2.*abs(h);
}

float checkersGrad( in vec2 uv, in vec2 ddx, in vec2 ddy )
{
    vec2 w = max(abs(ddx), abs(ddy)) + 0.01;    // filter kernel
    vec2 i = (tri(uv+0.5*w)-tri(uv-0.5*w))/w;   // analytical integral (box filter)
    return 0.5 - 0.5*i.x*i.y;                   // xor pattern
}

vec3 render(in vec2 uv, in vec2 px, in vec2 py) {
    float r = 5.;
    vec3 ro = vec3(r * cos(.1 * iTime), 2., r * sin(.1 * iTime));
    if(iMouse.z > 0.01) {
        float theta = iMouse.x / iResolution.x * 2. * PI;
        ro = vec3(r * cos(theta), 2., r * sin(theta));
    }
    vec3 ta = vec3(0., 1., 0.);
    mat3 cam = setCamera(ta, ro, 0.);
    float fl = 1.;
    vec3 rd = normalize(cam * vec3(uv, fl));
    vec3 bg = vec3(.7, .7, .9);
    vec3 color = bg - rd.y * vec3(.1);
    vec2 t = rayMarch(ro, rd);
    if(t.y > 0.) {
        vec3 p = ro + t.x * rd;
        vec3 n = (t.y < 1.1) ? vec3(0., 1., 0.) : calcNormal(p);
        vec3 light = vec3(5., 5., 0.);
        float dif = clamp(dot(normalize(light - p), n), 0., 1.);
        p += PRECISION * n;
        dif *= softShadow(p, normalize(light - p), 10.);
        float amb = 0.5 + 0.5 * dot(n, vec3(0., 1., 0.));
        vec3 c = vec3(0.);
        if (t.y > 1.9 && t.y < 2.1) {
            // shape1
            c = vec3(1., 0., 0.);
        } else if (t.y > 2.9 && t.y < 3.1) {
            // shape2
            c = vec3(1., 1., 0.);
        } else if (t.y > 3.9 && t.y < 4.1) {
            // shape3
            c = vec3(0., 1., 1.);
        } else if (t.y > 0.9 && t.y < 1.1) {
            // plane
            vec3 rdx = normalize(cam * vec3(px, fl));
            vec3 rdy = normalize(cam * vec3(py, fl));
            vec3 ddx = ro.y * (rd/rd.y - rdx/rdx.y);
            vec3 ddy = ro.y * (rd/rd.y - rdy/rdy.y);
            c = vec3(.1) + vec3(0.1) * checkersGrad(p.xz, ddx.xz, ddy.xz);
        }
        color = amb * c + dif * vec3(.7);
    }
    return sqrt(color);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            vec2 offset = 2. * (vec2(float(m), float(n)) / float(AA) - .5);
            vec2 uv = fixUV(fragCoord + offset);
            vec2 px = fixUV(fragCoord + vec2(1., 0.) + offset);
            vec2 py = fixUV(fragCoord + vec2(0., 1.) + offset);
            color += render(uv, px, py);
        }
    }
    fragColor = vec4(color / float(AA * AA), 1.);
}
