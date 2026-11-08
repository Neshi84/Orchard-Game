extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var _sprite_rest_y: float = sprite.position.y

func cross_orchard(perches: Array[Marker2D], landing: Marker2D, exit_x: float) -> void:
	await _run_to(perches.front().global_position.x - 125.0)
	for perch in perches:
		await _jump_to(perch.global_position, 46.0, 0.45)
	await _jump_to(landing.global_position, 42.0, 0.52)
	await _run_to(exit_x)

func _run_to(target_x: float) -> void:
	var distance := absf(target_x - global_position.x)
	var duration := distance / 440.0
	var run := create_tween().set_parallel()
	run.tween_property(self, "global_position:x", target_x, duration)
	run.tween_method(_set_run_pose, 0.0, distance * TAU / 54.0, duration)
	await run.finished
	sprite.rotation = 0.0
	sprite.position.y = _sprite_rest_y

func _set_run_pose(phase: float) -> void:
	sprite.position.y = _sprite_rest_y - absf(sin(phase)) * 5.0
	sprite.rotation = sin(phase) * 0.045

func _jump_to(target: Vector2, height: float, duration: float) -> void:
	var jump := create_tween()
	jump.tween_method(_set_jump_pose.bind(global_position, target, height), 0.0, 1.0, duration)
	await jump.finished

func _set_jump_pose(progress: float, start: Vector2, target: Vector2, height: float) -> void:
	var arc := sin(progress * PI)
	global_position = start.lerp(target, progress) - Vector2(0.0, height * arc)
	sprite.rotation = -sin(progress * TAU) * 0.16
