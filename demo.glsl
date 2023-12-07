float func(in vec2 uv) {
    // return step(0.,x);
    return abs(sin(uv.x) - uv.y) < fwidth(uv.x) ? 1. : 0.;
}

float segment(in vec2 p, in vec2 a, in vec2 b, in float w) {
    float f = 0.;

    // p = clamp(p, vec2(-1.,-1.), vec2(1.,1.));

    vec2 ba = b - a;
    vec2 pa = p - a;

    float proj = clamp(dot(ba, pa) / dot(ba, ba), 0.3,.8); 
    // float proj = dot(ba, pa) / dot(ba, ba);  
    float d = length(proj * ba - pa);

    if (d <= w) {
        f = 1.;
    }

    return clamp(f, 0., 1.);
}

vec2 fixUV(in vec2 uv) {
    return (uv - vec2(0.5, 0.5)) * 8.;
}


// float funcPlot(in vec2 uv) {
//     float f = 0.;
//     for(float i = 0.; i <= iResolution.x; i+=1.) {
//         float fx = fixUV(vec2(i, 0.)).x;
//         float nfx = fixUV(vec2(i + 1., 0.)).x;
//         f += segment(uv, vec2(fx, func(fx)), vec2(nfx, func(nfx)), 0.005);
//     }
//     return clamp(f, 0., 1.);
// }

float sdfRect(vec2 p, vec2 size) {
    vec2 d = abs(p) - size * 0.5;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}


vec3 crod(in vec2 uv) {
    vec3 col = vec3(0.);
    uv = fixUV(uv);
    vec2 cell = fract(uv);
    
    if (abs(cell.x) < fwidth(cell.x)) col = vec3(0., 0., 1.);
    if (abs(cell.y) < fwidth(cell.y)) col = vec3(0., 0., 1.);
    
    if (abs(uv.x) < fwidth(uv.x)) col = vec3(1.,0.,0.);
    
    if (abs(uv.y) < fwidth(uv.y)) col = vec3(0., 1., 0.);

    const float epsilon = 0.01;
    //uv
    col = mix(col, vec3(1.,1.,0.), func(uv));
    // col.r = smoothstep(1., .99, length(uv));

    col = mix(col, vec3(0.23), smoothstep(.2, .199, sdfRect(uv, vec2(1.,1.))));
    
    return col;
}

    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/ min(iResolution.x, iResolution.y);
    

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    
    // col = grid(uv);
    
    col = crod(uv);

    

    // Output to screen
    fragColor = vec4(col,1.0);
}