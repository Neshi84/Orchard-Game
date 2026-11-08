extends Area2D

## Node hierarchy expected:
##   Barrel (Area2D)
##   ├── Sprite2D
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

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = get_node_or_null("Label")

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_label()

## Call this from Game.gd whenever a fruit is clicked/collected.
## Returns false if the barrel is full/fermenting so you can decide what
## happens to a rejected fruit (e.g. leave it on the ground, bounce it back).
func add_fruit() -> bool:
	if state != State.ACCEPTING or current_amount >= capacity:
		return false
	current_amount += 1
	_update_label()
	if current_amount >= capacity:
		_start_fermenting()
	return true

func _update_label() -> void:
	if label:
		label.text = "%d / %d" % [current_amount, capacity]

func _start_fermenting() -> void:
	state = State.FERMENTING
	became_full.emit()
	_pulse_loop()
	await get_tree().create_timer(ferment_time).timeout
	if state == State.FERMENTING:
		_finish_fermenting()

func _pulse_loop() -> void:
	var base_scale: Vector2 = sprite.scale
	while state == State.FERMENTING:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", base_scale * pulse_scale, pulse_speed).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "scale", base_scale, pulse_speed).set_trans(Tween.TRANS_SINE)
		await tween.finished

func _finish_fermenting() -> void:
	state = State.READY
	sprite.scale = Vector2.ONE
	sprite.modulate = Color(1.0, 0.85, 0.4)  # golden glow = "ready to empty"
	ready_to_empty.emit()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_empty_into_still()

func _empty_into_still() -> void:
	if state != State.READY:
		return
	var amount := current_amount
	if accept_batch.is_valid() and not accept_batch.call(amount):
		return
	current_amount = 0
	state = State.ACCEPTING
	sprite.modulate = Color.WHITE
	_update_label()
	emptied.emit(amount)
