extends Area2D

## Attach this to an Area2D scene with a Sprite2D and CollisionShape2D child.
## Node hierarchy expected:
##   Fruit (Area2D)
##   ├── Sprite2D
##   └── CollisionShape2D

signal fell                # emitted the instant it lands on the ground
signal collected(fruit)    # emitted when the barrel accepts a fallen fruit
signal eaten
signal carried
signal rotted_away         # emitted right before it queue_frees from rotting

enum State { GROWING, RIPE, FALLING, FRESH_ON_GROUND, ROTTEN, GONE }

@export var fruit_kind: StringName = &"apple"
@export var grow_time: float = 2.0
@export var ripe_wait_min: float = 3.0
@export var ripe_wait_max: float = 8.0
@export var fall_duration: float = 0.6
@export var fresh_duration: float = 10.0
@export var rotten_duration: float = 6.0
@export var ground_y: float = 968.0
@export var ground_x_scatter: float = 20.0

var state: State = State.GROWING
var spawn_point: Node2D  # set by Tree.gd right after instancing
var accept_collection: Callable
var drop_handler: Callable
var dropped_from_cargo := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_event.connect(_on_input_event)
	input_pickable = false
	if dropped_from_cargo:
		fall_duration = 0.28
		_fall()
		return
	scale = Vector2.ZERO
	collision.disabled = true
	_grow()

func _grow() -> void:
	state = State.GROWING
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, grow_time).set_trans(Tween.TRANS_BACK)
	await tween.finished
	state = State.RIPE
	_wait_to_fall()

func _wait_to_fall() -> void:
	var wait_time := randf_range(ripe_wait_min, ripe_wait_max)
	await get_tree().create_timer(wait_time).timeout
	if state == State.RIPE:
		_fall()

func _fall() -> void:
	state = State.FALLING
	collision.disabled = false
	var target_x := global_position.x + randf_range(-ground_x_scatter, ground_x_scatter)
	var target_pos := Vector2(target_x, ground_y)
	var tween := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", target_pos, fall_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", randf_range(-1.0, 1.0), fall_duration)
	tween.chain().tween_callback(_land)

func _land() -> void:
	if state != State.FALLING:
		return
	fell.emit()
	state = State.FRESH_ON_GROUND
	input_pickable = true
	_start_rot_timer()

func try_carry() -> bool:
	if state != State.FALLING:
		return false
	state = State.GONE
	carried.emit()
	queue_free()
	return true

func _start_rot_timer() -> void:
	await get_tree().create_timer(fresh_duration).timeout
	if state == State.FRESH_ON_GROUND:
		_turn_rotten()

func _turn_rotten() -> void:
	state = State.ROTTEN
	sprite.modulate = Color(0.45, 0.3, 0.15)  # brownish tint, swap for a rotten texture if you have one
	await get_tree().create_timer(rotten_duration).timeout
	if state == State.ROTTEN:
		_disappear()

func _disappear() -> void:
	state = State.GONE
	rotted_away.emit()
	queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_get_collected()

func _get_collected() -> void:
	if not is_on_ground():
		return
	if accept_collection.is_valid() and not accept_collection.call(fruit_kind, sprite.texture):
		return
	_remove_from_ground()
	collected.emit(self)

func is_on_ground() -> bool:
	return state == State.FRESH_ON_GROUND or state == State.ROTTEN

func eat() -> void:
	if not is_on_ground():
		return
	_remove_from_ground()
	eaten.emit()

func _remove_from_ground() -> void:
	state = State.GONE
	input_pickable = false
	collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
