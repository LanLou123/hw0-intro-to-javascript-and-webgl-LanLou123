#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_EyePos;
uniform float u_time;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 4
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}
void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        vec3 vdir = normalize(fs_Pos.xyz - u_EyePos.xyz);
        vec3 halfwaydir =normalize(fs_LightVec.xyz+ vdir);
        float spec = pow(max(0.0,dot(halfwaydir,normalize(fs_Nor.xyz))),30.f);
        vec3 speccol = vec3(1,1,1);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);


        //Domain Warping credit to https://thebookofshaders.com/13/
        vec2 scrUV = gl_FragCoord.xy/100.f;
        vec3 color = vec3(0.0);

        vec2 q = vec2(0.);
        q.x = fbm( scrUV + 0.00*u_time);
        q.y = fbm( scrUV + vec2(1.0));

        vec2 r = vec2(0.);
        r.x = fbm( scrUV + 1.0*q + vec2(1.7,9.2)+ 0.15*u_time );
        r.y = fbm( scrUV + 1.0*q + vec2(8.3,2.8)+ 0.126*u_time);

        float f = fbm(scrUV+r);

        color = mix(vec3(0.101961,0.619608,0.666667),
                    vec3(0.666667,0.666667,0.498039),
                    clamp((f*f)*4.0,0.0,1.0));

        color = mix(color,
                    vec3(0,0,0.164706),
                    clamp(length(q),0.0,1.0));

        color = mix(color,
                    vec3(0.666667,1,1),
                    clamp(length(r.x),0.0,1.0));

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4((diffuseColor.rgb * lightIntensity + spec*speccol)*0.6+color*0.7, diffuseColor.a);
}