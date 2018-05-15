const vec3 LINE_COLOR = vec3(0.72, 0.94, 0.93);
const float SPEED = 1.2;
const float FRAMES = 20.0;
const float TIME_FACTOR = SPEED / FRAMES;
const vec2 CIRCLE_FRAMES = vec2(0.0, 12.0);
const float FLASH_FRAMES = 1.0;
const float FLICKER = 0.02;

float skewLine(vec2 uv, float size, float center, float amount,
               float plot, float direction) {
	float amplify = (center - 0.5) * 2.0 * direction;
    center += (amplify * amount);
    
    return min(
        smoothstep(center - size, center, plot),
        smoothstep(center + size, center, plot)
	);
}

float staggerLines(vec2 uv, vec3 range, float amount, vec2 lineRange, float direction) {
	float x = fract(
        uv.x * mix(
        	mix(range.y, range.z, amount),
        	mix(range.y, range.x, amount),
        	direction
        )
     );
    float size = mix(lineRange.x, lineRange.y, uv.x);
    return max(smoothstep(size, 0.0, x), smoothstep(1.0 - size, 1.0, x));
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec3 gradient (vec2 uv, vec3 start, vec3 end, vec2 center, float size) {
	float dis = distance(uv, center);
    dis = mix(dis, dis * 1.1, fract(abs(sin(iTime) + cos(iTime))));
    return mix(start, end, smoothstep(0.0, size, dis));
}

float circle (vec2 uv, vec2 center, float len, float size, float edge) {
	float dis = distance(uv, center);
    size *= 0.5;
    return min(
        smoothstep(len - size - edge, len - size, dis),
        smoothstep(len + size + edge, len + size, dis)
    );
}

vec3 grid (vec2 uv, vec3 col, float fTime, float frame, float flicker) {
	float size = 0.02;
    float edge = 0.03;
    
    float fpct = 1.0 - smoothstep(CIRCLE_FRAMES.x, CIRCLE_FRAMES.y, frame);
    
    float pct = 0.3 * flicker;
    float amount = fract(iTime * 0.2);
    
    float line = 0.0;
    for (float i = 0.0; i <= 1.0; i += 0.1) {
        line = max(line, skewLine(uv, 0.005, i, 0.8 * fpct, uv.y, 1.0 - uv.x));
    }
    
    line = max(
        line,
        staggerLines(
            uv,
            vec3(8.5, 11.0, 14.0),
            fpct,
            vec2(size, size - (size * amount * 0.25)),
            1.0 - uv.x
        )
    );
    
    
    col = mix(col, LINE_COLOR, line * pct);
    
    return col;
}

vec3 circles (vec2 uv, float scaleX, vec2 squv, vec3 col, float fTime,
              float frame, float flicker) {
    float size = 0.0;
    float edge = 0.005;
    vec2 center = vec2(scaleX * 0.5, 0.5);
    float pct = 0.6 * flicker;
    
    float fPct = smoothstep(CIRCLE_FRAMES.x, CIRCLE_FRAMES.y, frame);
    
    pct = max(
        pct,
        step(CIRCLE_FRAMES.y + 1.0, frame) *
        step(frame, CIRCLE_FRAMES.y + 1.0 + FLASH_FRAMES) *
        step(0.5, fract(iTime * 20.0))
    );
    
    // circle 1
    col = mix(col, LINE_COLOR, circle(squv, mix(vec2(center.x - 0.4, center.y), center, fPct),
                                      0.2, size, edge) * pct);
    
    col = mix(col, LINE_COLOR, circle(squv, mix(vec2(center.x - 0.3, center.y), center, fPct),
                                      0.3, size, edge) * pct);
    // circle 2
    col = mix(col, LINE_COLOR, circle(squv, mix(vec2(center.x - 0.2, center.y), center, fPct),
                                      0.4, size, edge) * pct);
    // circle 3
    col = mix(col, LINE_COLOR, circle(squv, center, 0.5, size, edge) * pct);
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    // scale x so that we have a square
    float scaleX = (iResolution.x / iResolution.y);
    vec2 squv = vec2(uv.x * scaleX, uv.y);

    // gradient
    vec3 col = gradient(uv, vec3(0.18, 0.46, 0.55), vec3(.089, 0.66, .732), vec2(0.0), 1.2);
    
    // change color
    col = mix(col, col * 0.99, random(vec2(1.0) * iTime));
    
    // frames
    float t = fract(iTime * TIME_FACTOR) * FRAMES;
    float fTime = fract(t);
    float frame = floor(t);
    
    // only flicker when animating
    float flicker = max(
        min(smoothstep(0.0, FLICKER, fTime), smoothstep(1.0, 1.0 - FLICKER, fTime)),
        step(CIRCLE_FRAMES.y + 0.1, frame)
    );
    
    
    // screen edges
    float edgeSize = 0.005;
    float edge = max(
        max(
        	smoothstep(edgeSize, 0.0, uv.x),
        	smoothstep(1.0 - edgeSize, 1.0, uv.x)
        ),
        max(
        	smoothstep(edgeSize, 0.0, uv.y),
        	smoothstep(1.0 - edgeSize, 1.0, uv.y)
        )
    );
    col = mix(col, col * 1.2, edge);
    
    // noise
    col.rgb = mix(col.rgb, vec3(random(uv * iTime)), 0.05);
    
    //grid
    col.rgb = grid(uv, col.rgb, fTime, frame, flicker);
    
    // circles
    col.rgb = circles(uv, scaleX, squv, col.rgb, fTime, frame, flicker);

    // Output to screen
    fragColor = vec4(col,1.0);
}
