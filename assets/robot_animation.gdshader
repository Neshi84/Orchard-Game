shader_type canvas_item;

uniform float walk_phase = 0.0;
uniform float walk_weight = 0.0;
uniform float pickup = 0.0;

float band(float value, float left, float center, float right) {
	return smoothstep(left, center, value) * (1.0 - smoothstep(center, right, value));
}

void vertex() {
	// The kettle robot's short legs move beneath its broad round body.
	float legs = smoothstep(0.80, 0.93, UV.y);
	float left_leg = 1.0 - smoothstep(0.46, 0.53, UV.x);
	float right_leg = smoothstep(0.51, 0.60, UV.x);
	float step = sin(walk_phase);
	VERTEX.x += legs * (left_leg - right_leg) * step * 4.0 * walk_weight;
	VERTEX.y -= legs * (left_leg * max(0.0, step) + right_leg * max(0.0, -step)) * 5.0 * walk_weight;

	float hands = band(UV.y, 0.40, 0.62, 0.79);
	float outer_arms = 1.0 - band(UV.x, 0.26, 0.51, 0.77);
	float arm_side = UV.x < 0.5 ? -1.0 : 1.0;
	VERTEX.y += outer_arms * hands * (arm_side * step * 4.0 * walk_weight + pickup * 11.0);
	VERTEX.x += outer_arms * hands * pickup * 4.0;

	float upper_body = 1.0 - smoothstep(0.80, 0.95, UV.y);
	VERTEX.y += upper_body * (sin(TIME * 2.2) * 0.6 * (1.0 - walk_weight) + pickup * 5.0);
	float head = 1.0 - smoothstep(0.30, 0.39, UV.y);
	VERTEX.x += head * pickup * 5.0;
	VERTEX.y += head * sin(TIME * 1.7) * 0.5 * (1.0 - walk_weight);
}
