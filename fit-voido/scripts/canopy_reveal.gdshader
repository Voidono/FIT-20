shader_type canvas_item;
varying vec2 world_position;
uniform vec2 player_position;
uniform vec2 reveal_radius = vec2(100.0, 110.0);
uniform float reveal_strength : hint_range(0.0, 1.0) = 0.0;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	float distance_from_player = length((world_position - player_position) / reveal_radius);
	float opening = 1.0 - smoothstep(0.65, 1.0, distance_from_player);
	COLOR.a *= 1.0 - opening * reveal_strength;
}
