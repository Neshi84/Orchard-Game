shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 0.0;
uniform bool purple_glass = false;
uniform vec2 fill_range = vec2(0.94, 0.34);
uniform float cork_cutoff = 0.154;

void fragment() {
	vec4 glass = COLOR;
	float glass_hue = purple_glass ? min(glass.r, glass.b) - glass.g : glass.g - max(glass.r, glass.b);
	float glass_mask = smoothstep(0.02, 0.16, glass_hue);
	// Preserve the label during filling and the original plum artwork once full.
	bool plum_label = UV.x > 0.38 && UV.x < 0.64 && UV.y > 0.54 && UV.y < 0.8;
	if (purple_glass && (fill_level >= 1.0 || plum_label)) {
		glass_mask = 0.0;
	}
	float lightness = dot(glass.rgb, vec3(0.299, 0.587, 0.114));
	vec3 empty_shadow = purple_glass ? vec3(0.64, 0.53, 0.72) : vec3(0.48, 0.65, 0.53);
	vec3 empty_glass = mix(empty_shadow, vec3(0.94, 0.99, 0.93), lightness);

	// Raise the surface from the foot to the shoulder of the bottle.
	float ripple = sin(UV.x * 26.0 + TIME * 8.0) * 0.006;
	float surface = mix(fill_range.x, fill_range.y, fill_level) + ripple;
	float filled = smoothstep(-0.003, 0.003, UV.y - surface) * step(0.001, fill_level);
	float meniscus = (1.0 - smoothstep(0.002, 0.009, abs(UV.y - surface))) * filled;
	vec3 liquid_tint = purple_glass ? vec3(1.08, 0.8, 1.0) : vec3(1.13, 0.97, 0.66);
	vec3 surface_glint = purple_glass ? vec3(0.23, 0.11, 0.29) : vec3(0.29, 0.21, 0.04);
	vec3 liquid = glass.rgb * liquid_tint + meniscus * surface_glint;
	glass.rgb = mix(glass.rgb, mix(empty_glass, liquid, filled), glass_mask);
	glass.a *= mix(1.0 - glass_mask * 0.27, 1.0, filled);

	// The cork is visible once the finished bottle is ready to collect.
	glass.a *= max(smoothstep(cork_cutoff - 0.003, cork_cutoff + 0.003, UV.y), step(1.0, fill_level));
	COLOR = glass;
}
