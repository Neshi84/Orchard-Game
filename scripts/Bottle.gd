extends Area2D

signal collected

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
		tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		tween.tween_callback(queue_free)
		collected.emit()
