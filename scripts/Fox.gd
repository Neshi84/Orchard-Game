extends Node2D

const AnimalAnimationMesh = preload("res://scripts/AnimalAnimationMesh.gd")
const STRIDE_LENGTH := 96.0
const SNATCH_OFFSET := Vector2(5.0, 4.0)

static var _animation_mesh: ArrayMesh

@onready var visual: Node2D = $Visual
@onready var body: MeshInstance2D = $Visual/Body
@onready var animation: ShaderMaterial = body.material
@onready var bottle_carry: Marker2D = $Visual/BottleCarry
@onready var _visual_rest_y: float = visual.position.y
@onready var _mouth_rest_position: Vector2 = bottle_carry.position

func _ready() -> void:
	if _animation_mesh == null:
		_animation_mesh = AnimalAnimationMesh.build(body.texture.get_size() * 0.078)
	body.mesh = _animation_mesh

func cross_orchard(
	perches: Array[Marker2D], landing: Marker2D, exit_x: float,
	bottle_stand: Marker2D, take_bottle: Callable
) -> void:
	await _run_to(perches.front().global_position.x - 125.0)
	for perch in perches:
		await _jump_to(perch.global_position, 46.0, 0.45)
	await _jump_to(landing.global_position, 42.0, 0.52)
	await _pass_bottle_stand(bottle_stand.global_position, take_bottle)
	await _run_to(exit_x)

func _pass_bottle_stand(bottle_position: Vector2, take_bottle: Callable) -> void:
	var ground_y := global_position.y
	await _run_to(bottle_position.x - 130.0)
	var mouth_reach := visual.to_global(_mouth_rest_position + SNATCH_OFFSET) - global_position
	var grab_position := bottle_position - mouth_reach
	grab_position.y -= 18.0
	await _jump_to(grab_position, 34.0, 0.34, true)
	var bottle = take_bottle.call(bottle_carry)
	if bottle != null:
		bottle.position = -bottle.mouth.position
	await _jump_to(Vector2(bottle_position.x + 60.0, ground_y), 32.0, 0.42)

func _run_to(target_x: float) -> void:
	var distance := absf(target_x - global_position.x)
	if is_zero_approx(distance):
		return
	var duration := distance / 440.0
	var run := create_tween().set_parallel()
	run.tween_property(self, "global_position:x", target_x, duration)
	run.tween_method(_set_run_pose.bind(distance), 0.0, distance, duration)
	await run.finished
	visual.rotation = 0.0
	visual.position.y = _visual_rest_y

func _set_run_pose(traveled: float, distance: float) -> void:
	var phase := traveled * TAU / STRIDE_LENGTH
	var weight := smoothstep(0.0, 20.0, minf(traveled, distance - traveled))
	animation.set_shader_parameter("run_phase", phase)
	animation.set_shader_parameter("run_weight", weight)
	visual.position.y = _visual_rest_y - (1.0 - cos(phase)) * 2.2 * weight
	visual.rotation = sin(phase) * 0.075 * weight

func _jump_to(target: Vector2, height: float, duration: float, reach_for_bottle: bool = false) -> void:
	var jump := create_tween()
	var initial_reach := bottle_carry.position - _mouth_rest_position
	jump.tween_method(
		_set_jump_pose.bind(global_position, target, height, initial_reach, reach_for_bottle),
		0.0, 1.0, duration
	)
	await jump.finished

func _set_jump_pose(
	progress: float, start: Vector2, target: Vector2, height: float,
	initial_reach: Vector2, reach_for_bottle: bool
) -> void:
	var arc := maxf(0.0, sin(progress * PI))
	global_position = start.lerp(target, progress) - Vector2(0.0, height * arc)
	visual.rotation = -sin(progress * TAU) * 0.22
	animation.set_shader_parameter("leap", arc)
	var landing := smoothstep(0.68, 0.88, progress) * (1.0 - smoothstep(0.88, 1.0, progress))
	animation.set_shader_parameter("landing", landing)

	var reach := initial_reach * (1.0 - smoothstep(0.0, 0.45, progress))
	if reach_for_bottle:
		reach = SNATCH_OFFSET * smoothstep(0.48, 1.0, progress)
	animation.set_shader_parameter("snout_offset", reach)
	bottle_carry.position = _mouth_rest_position + reach
