float sdfCircle(in vec2 c, in float r) {
    return length(c) - r;
}


vec3 crod(in vec2 uv) {
    vec3 col = vec3(0.4);

    vec2 grid = floor(mod(uv, 2.));
    if (grid.x == grid.y) col = vec3(0.6);

    col = mix(col, vec3(smoothstep(5. * fwidth(uv.x), 0., abs(sin(uv.x - iTime) - uv.y))), step(0., grid.x - grid.y));

    if (abs(fract(uv.x)) < fwidth(uv.x)) col = vec3(1.);
    if (abs(fract(uv.y)) < fwidth(uv.y)) col = vec3(1.);

    // if (abs(sin(uv.x - iTime) - uv.y) < 5. * fwidth(uv.x)) col = vec3(1.);
    // if ((sin(uv.x - iTime) - uv.y) > fwidth(uv.x)) col = vec3(.6);

    float d = sdfCircle(uv, .7);
    // d *=  1. - exp(-8. * abs(d));

    col = 1. - vec3(0.4, 0.5, 0.6) * sign(d);

    col *=  1. - exp(-3. * abs(d));

    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord/iResolution.xy - 0.5) * 2.;

    // uv = abs(fract(uv));

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    col = crod(uv);

    // col = mix(col, vec3(1.,1.,0.));

    // Output to screen
    fragColor = vec4(col,1.0);
}