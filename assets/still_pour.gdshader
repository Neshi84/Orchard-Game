shader_type canvas_item;

void fragment() {
	float center = 0.5 + sin(UV.y * 12.0 - TIME * 20.0) * UV.y * 0.12;
	float width = 0.36 - 0.1 * UV.y + sin(UV.y * 22.0 - TIME * 24.0) * 0.055;
	float edge = 1.0 - smoothstep(width - 0.1, width, abs(UV.x - center));
	float highlight = 1.0 - smoothstep(0.03, 0.23, abs(UV.x - center + 0.09));
	float shimmer = 0.82 + 0.18 * sin(UV.y * 32.0 - TIME * 30.0);
	vec3 liquid = mix(vec3(0.65, 0.30, 0.05), vec3(1.0, 0.82, 0.34), highlight * shimmer);
	COLOR = vec4(liquid, edge * 0.95);
}
