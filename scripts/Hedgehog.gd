extends Area2D

const Fruit = preload("res://scripts/Fruit.gd")

@onready var visual: Node2D = $Visual
@onready var facing: Node2D = $Visual/Facing
@onready var cargo: Node2D = $Visual/Facing/Cargo
@onready var back: CollisionShape2D = $Back
@onready var _back_rest_x: float = back.position.x

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func cross_orchard(first_tree_x: float, last_tree_x: float, exit_x: float) -> void:
	await _walk_to(last_tree_x)
	await _walk_to(first_tree_x)
	await _walk_to(last_tree_x)
	await _walk_to(exit_x)

func _walk_to(target_x: float) -> void:
	var direction := -1.0 if target_x < global_position.x else 1.0
	facing.transform = Transform2D(Vector2(direction, 0), Vector2(0, 1), Vector2.ZERO)
	back.position.x = _back_rest_x * direction
	var distance := absf(target_x - global_position.x)
	var duration := distance / 175.0
	var walk := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	walk.tween_property(self, "global_position:x", target_x, duration)
	walk.tween_method(_set_walk_pose, 0.0, distance * TAU / 32.0, duration)
	await walk.finished

func _set_walk_pose(phase: float) -> void:
	visual.position.y = -absf(sin(phase)) * 2.5
	visual.rotation = sin(phase) * 0.025

func _on_area_entered(area: Area2D) -> void:
	var fruit := area as Fruit
	if fruit == null or not fruit.try_carry():
		return

	var index := cargo.get_child_count()
	var icon := Sprite2D.new()
	icon.texture = fruit.sprite.texture
	icon.scale = fruit.sprite.global_scale
	icon.position = Vector2((index % 3 - 1) * 18.0, -floorf(index / 3.0) * 18.0)
	cargo.add_child(icon)
