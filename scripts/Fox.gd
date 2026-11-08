extends Node2D

@onready var visual: Node2D = $Visual
@onready var bottle_carry: Marker2D = $Visual/BottleCarry
@onready var _visual_rest_y: float = visual.position.y

func cross_orchard(
	perches: Array[Marker2D], landing: Marker2D, exit_x: float,
	bottle_stand: Marker2D, take_bottle: Callable
) -> void:
	await _run_to(perches.front().global_position.x - 125.0)
	for perch in perches:
		await _jump_to(perch.global_position, 46.0, 0.45)
	await _jump_to(landing.global_position, 42.0, 0.52)
	await _pass_bottle_stand(bottle_stand.global_position, take_bottle)
	await _run_to(exit_x)

func _pass_bottle_stand(bottle_position: Vector2, take_bottle: Callable) -> void:
	var ground_y := global_position.y
	await _run_to(bottle_position.x - 130.0)
	var grab_position := bottle_position - (bottle_carry.global_position - global_position)
	grab_position.y -= 18.0
	await _jump_to(grab_position, 34.0, 0.34)
	var bottle = take_bottle.call(bottle_carry)
	if bottle != null:
		bottle.position = -bottle.mouth.position
	await _jump_to(Vector2(bottle_position.x + 60.0, ground_y), 32.0, 0.42)

func _run_to(target_x: float) -> void:
	var distance := absf(target_x - global_position.x)
	var duration := distance / 440.0
	var run := create_tween().set_parallel()
	run.tween_property(self, "global_position:x", target_x, duration)
	run.tween_method(_set_run_pose, 0.0, distance * TAU / 54.0, duration)
	await run.finished
	visual.rotation = 0.0
	visual.position.y = _visual_rest_y

func _set_run_pose(phase: float) -> void:
	visual.position.y = _visual_rest_y - absf(sin(phase)) * 5.0
	visual.rotation = sin(phase) * 0.045

func _jump_to(target: Vector2, height: float, duration: float) -> void:
	var jump := create_tween()
	jump.tween_method(_set_jump_pose.bind(global_position, target, height), 0.0, 1.0, duration)
	await jump.finished

func _set_jump_pose(progress: float, start: Vector2, target: Vector2, height: float) -> void:
	var arc := sin(progress * PI)
	global_position = start.lerp(target, progress) - Vector2(0.0, height * arc)
	visual.rotation = -sin(progress * TAU) * 0.16
