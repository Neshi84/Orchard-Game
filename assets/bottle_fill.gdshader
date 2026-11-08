shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 glass = COLOR;
	float green = smoothstep(0.02, 0.16, glass.g - max(glass.r, glass.b));
	float lightness = dot(glass.rgb, vec3(0.299, 0.587, 0.114));
	vec3 empty_glass = mix(vec3(0.48, 0.65, 0.53), vec3(0.94, 0.99, 0.93), lightness);

	// Raise the surface from the foot to the shoulder of the bottle.
	float ripple = sin(UV.x * 26.0 + TIME * 8.0) * 0.006;
	float surface = mix(0.94, 0.34, fill_level) + ripple;
	float filled = smoothstep(-0.003, 0.003, UV.y - surface) * step(0.001, fill_level);
	float meniscus = (1.0 - smoothstep(0.002, 0.009, abs(UV.y - surface))) * filled;
	vec3 liquid = glass.rgb * vec3(1.13, 0.97, 0.66) + meniscus * vec3(0.29, 0.21, 0.04);
	glass.rgb = mix(glass.rgb, mix(empty_glass, liquid, filled), green);
	glass.a *= mix(1.0 - green * 0.27, 1.0, filled);

	// The cork is visible once the finished bottle is ready to collect.
	glass.a *= max(smoothstep(0.151, 0.157, UV.y), step(1.0, fill_level));
	COLOR = glass;
}
