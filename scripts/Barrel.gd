extends Area2D

## Node hierarchy expected:
##   Barrel (Area2D)
##   ├── Visual (Node2D)
##   ├── CollisionShape2D
##   └── Label            -- optional, shows "current / capacity"

signal became_full
signal ready_to_empty
signal emptied(amount)

enum State { ACCEPTING, FERMENTING, READY }

@export var capacity: int = 6
@export var ferment_time: float = 8.0
@export var pulse_scale: float = 1.08
@export var pulse_speed: float = 0.6

var state: State = State.ACCEPTING
var current_amount: int = 0
var accept_batch: Callable
var _batch_fruit_kind: StringName
var _shake_tween: Tween
var _pulse_tween: Tween
var _lid_tween: Tween

@onready var visual: Node2D = $Visual
@onready var lid: Node2D = $Visual/Lid
@onready var fruit_icon: TextureRect = $Visual/FruitIcon
@onready var _visual_rest_position: Vector2 = visual.position
@onready var _visual_rest_scale: Vector2 = visual.scale
@onready var _lid_rest_y: float = lid.position.y
@onready var label: Label = get_node_or_null("Label")

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_label()

## Accept only fruit that matches the first fruit in this batch.
func add_fruit(fruit_kind: StringName, fruit_texture: Texture2D) -> bool:
	if state != State.ACCEPTING or current_amount >= capacity:
		return false
	if current_amount == 0:
		_batch_fruit_kind = fruit_kind
		fruit_icon.texture = fruit_texture
	elif fruit_kind != _batch_fruit_kind:
		return false

	current_amount += 1
	_update_label()
	_shake()
	if current_amount >= capacity:
		_start_fermenting()
	return true

func _shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()

	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_shake_tween.tween_property(visual, "position", _visual_rest_position + Vector2(-6, 0), 0.04)
	_shake_tween.tween_property(visual, "position", _visual_rest_position + Vector2(5, 0), 0.06)
	_shake_tween.tween_property(visual, "position", _visual_rest_position + Vector2(-3, 0), 0.06)
	_shake_tween.tween_property(visual, "position", _visual_rest_position, 0.06)

func _update_label() -> void:
	if label:
		label.text = "%d / %d" % [current_amount, capacity]

func _start_fermenting() -> void:
	state = State.FERMENTING
	became_full.emit()
	_pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(visual, "scale", _visual_rest_scale * pulse_scale, pulse_speed)
	_pulse_tween.tween_property(visual, "scale", _visual_rest_scale, pulse_speed)
	_rock_lid()
	await get_tree().create_timer(ferment_time).timeout
	if state == State.FERMENTING:
		_finish_fermenting()

func _rock_lid() -> void:
	_lid_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_lid_tween.tween_method(_set_lid_tilt, 0.0, -1.0, 0.14)
	_lid_tween.tween_method(_set_lid_tilt, -1.0, 0.0, 0.20)
	_lid_tween.tween_method(_set_lid_tilt, 0.0, 1.0, 0.14)
	_lid_tween.tween_method(_set_lid_tilt, 1.0, 0.0, 0.20)
	_lid_tween.tween_interval(0.09)

func _set_lid_tilt(tilt: float) -> void:
	lid.rotation_degrees = tilt * 8.0
	lid.position.y = _lid_rest_y - absf(tilt) * 19.0

func _finish_fermenting() -> void:
	state = State.READY
	_lid_tween.kill()
	_pulse_tween.kill()
	_set_lid_tilt(0.0)
	visual.scale = _visual_rest_scale
	visual.modulate = Color(1.0, 0.85, 0.4)  # golden glow = "ready to empty"
	ready_to_empty.emit()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_empty_into_still()

func _empty_into_still() -> void:
	if state != State.READY:
		return
	var amount := current_amount
	if accept_batch.is_valid() and not accept_batch.call(amount, _batch_fruit_kind):
		return
	current_amount = 0
	_batch_fruit_kind = &""
	fruit_icon.texture = null
	state = State.ACCEPTING
	visual.modulate = Color.WHITE
	_update_label()
	emptied.emit(amount)
