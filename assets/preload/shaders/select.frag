#ifdef GL_ES
precision mediump float;
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);

    float glowSize = 3.0;
    float glowStrength = 0.01;
    vec4 glowColor = vec4(1.0, 1.0, 1.0, 1.0);

    vec4 color = texColor;
    for (float x = -glowSize; x <= glowSize; x += glowSize / 5.0) {
        for (float y = -glowSize; y <= glowSize; y += glowSize / 5.0) {
            vec4 cur_sample = texture(iChannel0, uv + vec2(x, y) / iResolution.xy);
            color += glowColor * cur_sample * glowStrength;
        }
    }

    fragColor = color;
}