float circle(in vec2 st, in float radius, in float edge){
    vec2 dist = st - vec2(0.5);
    return 1.0 - smoothstep(radius - (radius * edge),
                         radius + (radius * edge),
                         dot(dist , dist) * 4.0);
}

float line(float center, float size, float edge, float y) {
	return max(
        max(
        	smoothstep(center - size - edge, center - size, y) *
            smoothstep(center + size + edge, center + size, y),
        	smoothstep(center + size + edge - 1.0, center + size - 1.0, y)
        ),
        smoothstep(center - size + 1.0 - edge, center - size + 1.0, y)
    );
}

vec3 bottomGrid(in vec2 st, in vec3 col) {
    vec2 lines = vec2(10.0, 20.0);
    float activeVLines = 5.0;
    float maxVlines = 40.0;
    vec2 shift = vec2(mix(lines.x, maxVlines, st.y), lines.y);
    
    vec2 suv = vec2((st.x * shift.x) - (shift.x * 0.5), st.y * shift.y);
    vec2 fuv = fract(suv);
    vec2 iuv = floor(suv);
    
    // black
    col *= step(activeVLines, suv.y);
    
    // glow lines
    vec3 glowCol = vec3(0.3, 1.0, 0.3);
    float time = 1.0 - fract(iTime * 0.6);
    
    float gvLine = line(0.0, 0.04, 0.08, fuv.x);
    float ghLine = max(
        line(time, 0.12, 0.24, fuv.y),
        line(0.0, 0.12, 0.12, fuv.y) * step(activeVLines - 0.16, suv.y)
    );
    
    col = mix(col, glowCol, max(ghLine, gvLine) * step(suv.y, activeVLines + .16) * 0.3);
    
    // lines
    vec3 lineCol = vec3(1.0, 1.0, 1.0);
    
    float vLine = line(0.0, 0.0025, 0.03, fuv.x);
    float hLine = max(
        line(time, 0.015, 0.06, fuv.y),
        line(0.0, 0.03, 0.03, fuv.y) * step(activeVLines - 0.04, suv.y)
    );
    
    col = mix(col, lineCol, max(hLine, vLine) * step(suv.y, activeVLines + .04));
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    float scaleX = iResolution.x / iResolution.y;
    vec2 sunUV = vec2((uv.x * scaleX) - ((scaleX - 1.0) * 0.5), uv.y);
    vec2 texelSize = vec2(1.0 / iResolution.x, 1.0 / iResolution.y);

    
    float sunPct = circle(sunUV, 0.5, 0.01);
    
    // background
    fragColor += (1.0 - fragColor.r) * vec4(0.2, 0.129, 0.286, 1);
    
    // stars
    fragColor.rgb += vec3(max(90.* fract(dot(sin(fragCoord),fragCoord))-89.5, 0.0));
    fragColor.rgb += vec3(max(70.* fract(dot(cos(fragCoord),fragCoord))-69.7, 0.0));
    
    // sun haze
    float sunHazePct = circle(sunUV, 0.57, 0.2) * 0.35;
    fragColor.rgb = ((1.0 - sunHazePct) * fragColor.rgb) + (vec3(0.909, 0.167, 0.596) * sunHazePct);
    
    // sun color
    // get a 0 -> 1 value within our sun
    float sunValue = smoothstep(0.3, 0.63, uv.y);
    // line size increases the closer we are to the bottom of the sun
    float lineSize = floor(mix(80.0, 0.0, sunValue)) * texelSize.y;
    // lerp between our sun colors to get a gradient
    vec3 sunColor = mix(vec3(0.909, 0.167, 0.596), vec3(1, 0.913, 0.305), sunValue);
    
    // line speed ( 1 - to make it go down)
    float lineInt = 1.0 - fract(iTime * 0.3);
    
    // line count
    float lineY = fract(uv.y * 14.0);
    
    // select our lines, invert so that active lines = 0
    float lines = 1.0 - line(lineInt, lineSize, 0.05, lineY);
    
    // cutoff the top lines
    lines = max(lines, step(0.6, uv.y));
    
    // cancel out sun on lines
    sunPct *= lines;
    
    // add main circle
    fragColor.rgb = ((1.0 - sunPct) * fragColor.rgb) + (sunColor * sunPct);
    
    fragColor.rgb = bottomGrid(uv, fragColor.rgb);
}
