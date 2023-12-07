#define TMIN 0.1
#define TMAX 100.
#define RAYMARCH_TIME 128
#define PRECISION .001
#define AA 3
#define PI 3.14159265

vec2 fixUV(in vec2 c) {
    return (2. * c - iResolution.xy) / min(iResolution.x, iResolution.y);
}

float sdBox( vec3 p, vec3 b)
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdfSphere(in vec3 p) {
    return length(p + vec3(sin(iTime) * 4., 0., 0.)) - 1.;
    // return sdBoxFrame(p, vec3(1.5,1.3,1.5), 0.05 );
}

float sdfPlane(in vec3 p) {
    float d = sdfSphere(p - vec3(3.));
    return min(d, p.y);
}


float rayMarch(in vec3 ro, in vec3 rd) {
    float t = TMIN;
    for(int i = 0; i < RAYMARCH_TIME && t < TMAX; i++) {
        vec3 p = ro + t * rd;
        float d = sdfPlane(p);
        if(d < PRECISION)
            break;
        t += d;
    }
    return t;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 p) {
    const float h = 0.0001;
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * sdfPlane(p + k.xyy * h) +
        k.yyx * sdfPlane(p + k.yyx * h) +
        k.yxy * sdfPlane(p + k.yxy * h) +
        k.xxx * sdfPlane(p + k.xxx * h));
}

mat3 setCamera(vec3 ta, vec3 ro, float cr) {
    vec3 z = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.);// 0 1 0
    vec3 x = normalize(cross(z, cp));
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 render(vec2 uv) {
    vec3 color = vec3(0.);
    // vec3 ro = 4. * vec3(2. * cos(iTime), 1., 2. * sin(iTime));
    vec3 ro = 3. * vec3(4.);
    // if (iMouse.z > 0.01) {
    //     float theta = iMouse.x / iResolution.x * 2. * PI;
    //     ro = vec3(2. * cos(theta), 1., 2. * sin(theta));
    // }
    vec3 ta = vec3(0.);
    mat3 cam = setCamera(ta, ro, 0.);
    vec3 rd = normalize(cam * vec3(uv, 1.));
    float t = rayMarch(ro, rd);
    if(t < TMAX) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        vec3 light = vec3(5., 8., 0.);
        float dif = clamp(dot(normalize(light - p), n), 0., 1.);
        float st = rayMarch(p, normalize(light - p));
        if (st < TMAX) {
            dif *= 0.1;
        }
        float amb = 0.5 + 0.5 * dot(n, vec3(0., 1., 0.));
        color = amb * vec3(0.13) + dif * vec3(1.);
    }
    return sqrt(color);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            vec2 offset = 2. * (vec2(float(m), float(n)) / float(AA) - .5);
            vec2 uv = fixUV(fragCoord + offset);
            color += render(uv);
        }
    }
    fragColor = vec4(color / float(AA * AA), 1.);
}
