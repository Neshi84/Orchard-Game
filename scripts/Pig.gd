extends Node2D

@export var walk_speed: float = 235.0
@export var snout_reach: float = 46.0

const AnimalAnimationMesh = preload("res://scripts/AnimalAnimationMesh.gd")
const STRIDE_LENGTH := 56.0

static var _animation_mesh: ArrayMesh

@onready var visual: MeshInstance2D = $Visual
@onready var animation: ShaderMaterial = visual.material

func _ready() -> void:
	if _animation_mesh == null:
		_animation_mesh = AnimalAnimationMesh.build(visual.texture.get_size() * 0.1)
	visual.mesh = _animation_mesh

func visit(fallen_fruits: Array) -> void:
	var exit_x := global_position.x
	fallen_fruits.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for fruit in fallen_fruits:
		if not is_instance_valid(fruit) or not fruit.is_on_ground():
			continue
		await _walk_to(fruit.global_position.x - snout_reach)
		if is_instance_valid(fruit) and fruit.is_on_ground():
			await _eat(fruit)
	await _walk_to(exit_x)

func _walk_to(target_x: float) -> void:
	var distance := absf(target_x - global_position.x)
	if distance < 1.0:
		return
	visual.scale.x = signf(target_x - global_position.x)
	var duration := distance / walk_speed
	var walk := create_tween().set_parallel()
	walk.tween_property(self, "global_position:x", target_x, duration)
	walk.tween_method(_set_walk_pose.bind(distance), 0.0, distance, duration)
	await walk.finished
	animation.set_shader_parameter("walk_weight", 0.0)

func _set_walk_pose(traveled: float, distance: float) -> void:
	animation.set_shader_parameter("walk_phase", traveled * TAU / STRIDE_LENGTH)
	animation.set_shader_parameter("walk_weight", smoothstep(0.0, 12.0, minf(traveled, distance - traveled)))

func _eat(fruit) -> void:
	visual.scale.x = 1.0
	var dip := create_tween().set_trans(Tween.TRANS_SINE)
	dip.tween_property(animation, "shader_parameter/head_dip", 1.0, 0.18)
	await dip.finished
	if is_instance_valid(fruit) and fruit.is_on_ground():
		fruit.eat()
		var chew := create_tween()
		chew.tween_method(_set_chew_pose, 0.0, TAU * 3.0, 0.36)
		await chew.finished
		animation.set_shader_parameter("chew", 0.0)
	var lift := create_tween().set_trans(Tween.TRANS_SINE)
	lift.tween_property(animation, "shader_parameter/head_dip", 0.0, 0.18)
	await lift.finished

func _set_chew_pose(phase: float) -> void:
	animation.set_shader_parameter("chew", 0.5 - 0.5 * cos(phase))
