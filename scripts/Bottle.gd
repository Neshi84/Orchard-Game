extends Area2D

signal collected

const BottleCrate = preload("res://scripts/BottleCrate.gd")

var crate: BottleCrate

@onready var sprite: Sprite2D = $Sprite2D
@onready var mouth: Marker2D = $Mouth

func _ready() -> void:
	input_event.connect(_on_input_event)

func set_fill_level(level: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("fill_level", level)

func mark_full() -> void:
	set_fill_level(1.0)
	input_pickable = true

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not input_pickable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		input_pickable = false
		var tween := create_tween()
		if is_instance_valid(crate):
			var slot := crate.reserve_slot(self)
			var opening := slot.global_position - Vector2(0.0, 14.0)
			tween.tween_method(_fly_to_crate.bind(global_position, opening), 0.0, 1.0, 0.36)
			tween.tween_callback(crate.store_bottle.bind(self, slot))
			tween.tween_property(self, "position", Vector2.ZERO, 0.12)
		else:
			tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
			tween.tween_callback(queue_free)
		collected.emit()

func _fly_to_crate(progress: float, start: Vector2, opening: Vector2) -> void:
	var arc := sin(progress * PI)
	global_position = start.lerp(opening, progress) - Vector2(0.0, 52.0 * arc)
	scale = Vector2.ONE * lerpf(1.0, 0.65, progress)
	rotation = 0.2 * arc
