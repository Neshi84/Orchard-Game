extends Node2D

const RobotArtwork := preload("res://scripts/RobotArtwork.gd")
# The horizontal distance from the robot's origin to its claw in the contact pose.
const CLAW_REACH := 55.0
const GAIT_SPEED := 170.0

@export var walk_speed: float = GAIT_SPEED

var find_fruit: Callable
var can_collect: Callable
var _target: Node2D
var _search_delay := 0.0
var _direction := 1.0

@onready var facing: Node2D = $Visual/Facing
@onready var artwork: RobotArtwork = $Visual/Facing/Artwork

func _ready() -> void:
	artwork.grip_closed.connect(_collect_at_grip)

func _physics_process(delta: float) -> void:
	if artwork.player.current_animation == &"pickup":
		return

	if not find_fruit.is_valid() or not can_collect.is_valid():
		artwork.idle(delta)
		return

	if not is_instance_valid(_target) or not can_collect.call(_target):
		_target = null
		_search_delay -= delta
		if _search_delay <= 0.0:
			_target = find_fruit.call(global_position)
			_search_delay = 0.4
		if _target == null:
			artwork.idle(delta)
			return
		var distance := _target.global_position.x - global_position.x
		if not is_zero_approx(distance):
			_direction = signf(distance)
		facing.transform = Transform2D(Vector2(_direction, 0), Vector2.DOWN, Vector2.ZERO)

	var stand_x := _target.global_position.x - _direction * CLAW_REACH
	if not is_equal_approx(global_position.x, stand_x):
		var walk_direction := signf(stand_x - global_position.x)
		global_position.x = move_toward(global_position.x, stand_x, walk_speed * delta)
		artwork.walk(walk_direction * _direction * walk_speed / GAIT_SPEED)
		return
	artwork.pick_up()

func _collect_at_grip() -> void:
	if is_instance_valid(_target) and can_collect.is_valid() and can_collect.call(_target):
		_target._get_collected()
	_target = null
	_search_delay = 0.25
