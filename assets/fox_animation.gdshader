shader_type canvas_item;

uniform float run_phase = 0.0;
uniform float run_weight = 0.0;
uniform float leap = 0.0;
uniform float landing = 0.0;
uniform vec2 snout_offset = vec2(0.0);

float band(float position, float left, float center, float right) {
	return smoothstep(left, center, position) * (1.0 - smoothstep(center, right, position));
}

vec2 stride(float phase) {
	return vec2(-8.0 * cos(phase), 3.0 - 8.0 * max(0.0, sin(phase)));
}

void vertex() {
	// The rear paws sit beneath the haunch, and the forepaws beneath the chest.
	float paw_height = smoothstep(0.56, 0.82, UV.y);
	float rear = band(UV.x, 0.20, 0.33, 0.49) * paw_height;
	float front = band(UV.x, 0.56, 0.74, 0.89) * paw_height;
	float paw_pair_offset = smoothstep(0.30, 0.37, UV.x) * 0.8;
	float forepaw_offset = smoothstep(0.70, 0.80, UV.x) * 0.8;

	VERTEX += rear * stride(run_phase + paw_pair_offset) * run_weight;
	VERTEX += front * stride(run_phase + PI + forepaw_offset) * run_weight;
	VERTEX += rear * vec2(-9.0, -4.0) * leap;
	VERTEX += front * vec2(12.0, 1.0) * leap;
	VERTEX += (rear * vec2(3.0, -5.0) + front * vec2(-4.0, -5.0)) * landing;
	VERTEX.y += 3.0 * landing * (1.0 - paw_height);

	float tail = 1.0 - smoothstep(0.10, 0.43, UV.x);
	VERTEX.y += tail * (sin(TIME * 3.0) * 1.4 + sin(run_phase - 0.8) * 5.0 * run_weight - 8.0 * leap);
	float ears = band(UV.x, 0.64, 0.78, 0.89) * (1.0 - smoothstep(0.20, 0.42, UV.y));
	VERTEX.x -= ears * (2.5 * (1.0 + sin(run_phase)) * run_weight + 5.0 * leap);

	// The mouth marker uses this same offset when the fox reaches for a bottle.
	VERTEX += smoothstep(0.68, 0.89, UV.x) * snout_offset;
}
