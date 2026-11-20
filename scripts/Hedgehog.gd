extends Area2D

const Fruit = preload("res://scripts/Fruit.gd")
const AnimalAnimationMesh = preload("res://scripts/AnimalAnimationMesh.gd")
const STRIDE_LENGTH := 38.0

static var _animation_mesh: ArrayMesh

var _walk: Tween
var _curl_motion: Tween
var _curled := false
var _curl_amount := 0.0
var _clear_time := 0.0

@onready var visual: Node2D = $Visual
@onready var facing: Node2D = $Visual/Facing
@onready var walking_sprite: MeshInstance2D = $Visual/Facing/Body
@onready var animation: ShaderMaterial = walking_sprite.material
@onready var curled_sprite: Sprite2D = $Visual/Facing/Curled
@onready var _curled_rest_scale: Vector2 = curled_sprite.scale
@onready var cargo: Node2D = $Visual/Facing/Cargo
@onready var back: CollisionShape2D = $Back
@onready var _back_rest_x: float = back.position.x

func _ready() -> void:
	if _animation_mesh == null:
		_animation_mesh = AnimalAnimationMesh.build(walking_sprite.texture.get_size() * 0.098)
	walking_sprite.mesh = _animation_mesh
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	var fox := get_tree().get_first_node_in_group("fox") as Node2D
	if fox != null and global_position.distance_squared_to(fox.global_position) < 105.0 * 105.0:
		_clear_time = 0.0
		if not _curled:
			_curl_up()
	elif _curled:
		_clear_time += delta
		if _clear_time >= 1.4:
			_curled = false
			_animate_curl(0.0, 0.24)
			_curl_motion.tween_callback(_resume_walk)

func _curl_up() -> void:
	_curled = true
	if _walk:
		_walk.pause()
	_animate_curl(1.0, 0.18)
	for icon in cargo.get_children():
		var drop: Callable = icon.get_meta("drop_handler")
		if drop.is_valid():
			drop.call(icon.global_position)
		icon.queue_free()

func _animate_curl(target: float, duration: float) -> void:
	if _curl_motion:
		_curl_motion.kill()
	_curl_motion = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_curl_motion.tween_method(_set_curl_pose, _curl_amount, target, duration)

func _set_curl_pose(amount: float) -> void:
	_curl_amount = amount
	animation.set_shader_parameter("tuck", amount)
	var curled_weight := smoothstep(0.48, 0.68, amount)
	walking_sprite.visible = curled_weight < 1.0
	walking_sprite.self_modulate.a = 1.0 - curled_weight
	curled_sprite.visible = curled_weight > 0.0
	curled_sprite.self_modulate.a = curled_weight
	curled_sprite.rotation = 0.45 * (1.0 - amount)
	curled_sprite.scale = _curled_rest_scale * lerpf(0.83, 1.0, amount)
	visual.position.y = -sin(amount * PI) * 4.0

func _resume_walk() -> void:
	if _walk:
		_walk.play()

func cross_orchard(first_tree_x: float, last_tree_x: float, exit_x: float) -> void:
	await _walk_to(last_tree_x)
	await _walk_to(first_tree_x)
	await _walk_to(last_tree_x)
	await _walk_to(exit_x)

func _walk_to(target_x: float) -> void:
	var direction := -1.0 if target_x < global_position.x else 1.0
	facing.transform = Transform2D(Vector2(direction, 0), Vector2(0, 1), Vector2.ZERO)
	back.position.x = _back_rest_x * direction
	var distance := absf(target_x - global_position.x)
	var duration := distance / 175.0
	_walk = create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_walk.tween_property(self, "global_position:x", target_x, duration)
	_walk.tween_method(_set_walk_pose.bind(distance), 0.0, distance, duration)
	if _curled or (_curl_motion and _curl_motion.is_running()):
		_walk.pause()
	await _walk.finished
	_walk = null

func _set_walk_pose(traveled: float, distance: float) -> void:
	var phase := traveled * TAU / STRIDE_LENGTH
	var weight := smoothstep(0.0, 7.0, minf(traveled, distance - traveled))
	animation.set_shader_parameter("walk_phase", phase)
	animation.set_shader_parameter("walk_weight", weight)
	visual.position.y = -absf(sin(phase)) * 1.6 * weight

func _on_area_entered(area: Area2D) -> void:
	var fruit := area as Fruit
	if _curled or fruit == null or not fruit.try_carry():
		return

	var index := cargo.get_child_count()
	var icon := Sprite2D.new()
	icon.texture = fruit.sprite.texture
	icon.scale = fruit.sprite.global_scale
	icon.position = Vector2((index % 3 - 1) * 18.0, -floorf(index / 3.0) * 18.0)
	icon.set_meta("drop_handler", fruit.drop_handler)
	cargo.add_child(icon)
