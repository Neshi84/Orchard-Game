shader_type canvas_item;

uniform float walk_phase = 0.0;
uniform float walk_weight = 0.0;
uniform float head_dip = 0.0;
uniform float chew = 0.0;

float band(float position, float left, float center, float right) {
	return smoothstep(left, center, position) * (1.0 - smoothstep(center, right, position));
}

vec2 step_offset(float phase) {
	return vec2(-5.5 * cos(phase), -6.0 * max(0.0, sin(phase)));
}

void vertex() {
	// Hoof positions in the source texture, from the left edge to the snout.
	float leg_height = smoothstep(0.57, 0.79, UV.y);
	vec2 legs = band(UV.x, 0.035, 0.105, 0.18) * step_offset(walk_phase);
	legs += band(UV.x, 0.18, 0.258, 0.327) * step_offset(walk_phase + PI);
	legs += band(UV.x, 0.34, 0.425, 0.503) * step_offset(walk_phase + PI);
	legs += band(UV.x, 0.49, 0.558, 0.63) * step_offset(walk_phase);
	VERTEX += legs * leg_height * walk_weight;

	float breath = sin(TIME * 3.2) * (1.0 - walk_weight);
	float bounce = 1.8 * (1.0 - cos(2.0 * walk_phase)) * walk_weight;
	VERTEX.y -= (bounce + 0.8 * breath) * (1.0 - leg_height);

	float head = smoothstep(0.48, 0.81, UV.x);
	float jaw = head * smoothstep(0.60, 0.79, UV.y);
	VERTEX += head_dip * head * vec2(2.0, 9.0);
	VERTEX += chew * jaw * vec2(-0.9, -4.0);

	float ear = band(UV.x, 0.49, 0.615, 0.73) * band(UV.y, 0.32, 0.53, 0.63);
	VERTEX.y += ear * (sin(walk_phase + 0.9) * 3.6 * walk_weight + chew * 1.3);
	float tail = (1.0 - smoothstep(0.13, 0.20, UV.x)) * (1.0 - smoothstep(0.35, 0.42, UV.y));
	VERTEX.y += tail * sin(TIME * 10.0) * (1.3 + 1.2 * walk_weight);
}
