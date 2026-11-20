shader_type canvas_item;

uniform float walk_phase = 0.0;
uniform float walk_weight = 0.0;
uniform float tuck = 0.0;

float band(float position, float left, float center, float right) {
	return smoothstep(left, center, position) * (1.0 - smoothstep(center, right, position));
}

vec2 paw_stride(float phase) {
	return vec2(-4.4 * cos(phase), -4.8 * max(0.0, sin(phase)));
}

void vertex() {
	// Mask the four paws below the skirt of quills.
	float paw_height = smoothstep(0.72, 0.83, UV.y);
	vec2 paws = band(UV.x, 0.25, 0.31, 0.37) * paw_stride(walk_phase);
	paws += band(UV.x, 0.35, 0.41, 0.46) * paw_stride(walk_phase + PI);
	paws += band(UV.x, 0.44, 0.50, 0.59) * paw_stride(walk_phase + PI);
	paws += band(UV.x, 0.57, 0.65, 0.72) * paw_stride(walk_phase);
	VERTEX += paws * paw_height * walk_weight * (1.0 - tuck);

	float snout = smoothstep(0.66, 0.80, UV.x);
	float quills = (1.0 - smoothstep(0.56, 0.73, UV.x)) * (1.0 - paw_height);
	VERTEX.y += quills * (sin(TIME * 3.0) * 0.7 + sin(walk_phase + UV.x * 6.0) * 1.3 * walk_weight);
	VERTEX.y += snout * (sin(TIME * 11.0) * 0.75 + sin(walk_phase) * 1.4 * walk_weight) * (1.0 - tuck);

	VERTEX.x *= 1.0 - 0.22 * tuck;
	VERTEX += snout * vec2(-8.0, 8.0) * tuck;
	VERTEX.y -= paw_height * 12.0 * tuck;
}
