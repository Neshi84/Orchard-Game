extends RigidBody2D

## Node hierarchy expected:
##   Bottle (RigidBody2D)
##   ├── Sprite2D
##   └── CollisionShape2D
##
## If you'd rather bottles not use physics at all, change the root node
## type to Node2D/Sprite2D and delete the apply_impulse line in pop_out() --
## it'll just appear at the spawn point.

signal collected

var _collected: bool = false

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)

func pop_out() -> void:
	var impulse := Vector2(randf_range(-60, 60), randf_range(-120, -60))
	apply_impulse(impulse)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _collected:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_get_collected()

func _get_collected() -> void:
	_collected = true
	input_pickable = false
	collected.emit()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
