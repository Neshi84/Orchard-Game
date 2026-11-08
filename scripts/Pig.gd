extends Node2D

@export var walk_speed: float = 235.0
@export var snout_reach: float = 46.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var _sprite_rest_y: float = sprite.position.y

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
	sprite.flip_h = target_x < global_position.x
	var duration := distance / walk_speed
	var walk := create_tween().set_parallel()
	walk.tween_property(self, "global_position:x", target_x, duration)
	walk.tween_method(_set_walk_pose, 0.0, distance * TAU / 42.0, duration)
	await walk.finished
	sprite.rotation = 0.0
	sprite.position.y = _sprite_rest_y

func _set_walk_pose(phase: float) -> void:
	sprite.position.y = _sprite_rest_y - absf(sin(phase)) * 3.5
	sprite.rotation = sin(phase) * 0.035

func _eat(fruit) -> void:
	sprite.flip_h = false
	var dip := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	dip.tween_property(sprite, "rotation_degrees", 9.0, 0.15)
	dip.tween_property(sprite, "position:y", _sprite_rest_y + 1.0, 0.15)
	await dip.finished
	if is_instance_valid(fruit):
		fruit.eat()
	var lift := create_tween().set_trans(Tween.TRANS_SINE)
	lift.tween_interval(0.12)
	lift.tween_property(sprite, "rotation", 0.0, 0.17)
	lift.parallel().tween_property(sprite, "position:y", _sprite_rest_y, 0.17)
	await lift.finished
