extends Node2D

@export var walk_speed: float = 170.0

var find_fruit: Callable
var can_collect: Callable
var _target: Node2D
var _search_delay := 0.0
var _pickup_time := 0.0
var _step_phase := 0.0
var _facing_left := false
var _idle_delay := 0.0
var _steam_burst: CPUParticles2D

@onready var visual: Node2D = $Visual
@onready var facing: Node2D = $Visual/Facing
@onready var sprite: Sprite2D = $Visual/Facing/Artwork

func _ready() -> void:
	sprite.scale = Vector2.ONE * (151.5 / sprite.texture.get_height())
	_idle_delay = randf_range(2.5, 5.0)
	_steam_burst = $Visual/Facing/BoilerSteam.duplicate()
	_steam_burst.name = "IdleSteamBurst"
	_steam_burst.emitting = false
	_steam_burst.one_shot = true
	_steam_burst.preprocess = 0.0
	_steam_burst.explosiveness = 0.85
	_steam_burst.amount = 12
	_steam_burst.lifetime = 0.7
	_steam_burst.initial_velocity_min = 25.0
	_steam_burst.initial_velocity_max = 40.0
	facing.add_child(_steam_burst)

func _physics_process(delta: float) -> void:
	if not find_fruit.is_valid() or not can_collect.is_valid():
		return

	if not is_instance_valid(_target) or not can_collect.call(_target):
		_target = null
		_pickup_time = 0.0
		visual.position.y = 0.0
		visual.rotation = 0.0
		_search_delay -= delta
		if _search_delay > 0.0:
			_idle(delta)
			return
		_target = find_fruit.call(global_position)
		_search_delay = 0.4
		if _target == null:
			_idle(delta)
			return

	var distance := _target.global_position.x - global_position.x
	_idle_delay = randf_range(2.5, 5.0)
	if absf(distance) > 28.0:
		_face_direction(distance < 0.0)
		global_position.x = move_toward(global_position.x, _target.global_position.x, walk_speed * delta)
		_step_phase += delta * 15.0
		visual.position.y = -absf(sin(_step_phase)) * 1.5
		visual.rotation = sin(_step_phase) * 0.015

		return

	_pickup_time += delta
	var dip := sin(minf(_pickup_time / 0.35, 1.0) * PI)
	visual.position.y = dip * 8.0
	visual.rotation = dip * 0.14 * (-1.0 if _facing_left else 1.0)
	if _pickup_time >= 0.35:
		# Fruit collection checks the barrels again before consuming the fruit.
		_target._get_collected()
		_target = null
		_pickup_time = 0.0
		_search_delay = 0.25
		visual.position.y = 0.0
		visual.rotation = 0.0

func _face_direction(left: bool) -> void:
	_facing_left = left
	var direction := -1.0 if left else 1.0
	facing.transform = Transform2D(Vector2(direction, 0), Vector2(0, 1), Vector2.ZERO)

func _idle(delta: float) -> void:
	_idle_delay -= delta
	if _idle_delay > 0.0:
		return
	_idle_delay = randf_range(3.0, 6.0)
	_steam_burst.restart()
