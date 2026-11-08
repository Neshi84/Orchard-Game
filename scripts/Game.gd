extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Routes fruit to the barrels, keeps bottle totals, and schedules wildlife.

@export var pig_scene: PackedScene
@export var pig_visit_min: float = 18.0
@export var pig_visit_max: float = 34.0
@export var fox_scene: PackedScene
@export var hedgehog_scene: PackedScene

@onready var trees: Array = [$Tree, $PlumTree, $PearTree]
@onready var barrels: Array = [$Barrel, $Barrel2, $Barrel3]
@onready var still = $Still
@onready var pig_entrance: Marker2D = $PigEntrance
@onready var pig_visit_timer: Timer = $PigVisitTimer
@onready var squirrel: Sprite2D = $Squirrel
@onready var squirrel_peek_timer: Timer = $SquirrelPeekTimer
@onready var fox_entrance: Marker2D = $FoxEntrance
@onready var fox_landing: Marker2D = $FoxLanding
@onready var fox_visit_timer: Timer = $FoxVisitTimer
@onready var hedgehog_entrance: Marker2D = $HedgehogEntrance
@onready var hedgehog_visit_timer: Timer = $HedgehogVisitTimer
@onready var bottle_counter_labels: Dictionary[StringName, Label] = {
	&"apple": $UI/BottleNoticeBoard/AppleTotal/BottleCount,
	&"plum": $UI/BottleNoticeBoard/PlumTotal/BottleCount,
	&"pear": $UI/BottleNoticeBoard/PearTotal/BottleCount,
}

var bottle_counts: Dictionary[StringName, int] = {&"apple": 0, &"plum": 0, &"pear": 0}

func _ready() -> void:
	for tree in trees:
		tree.accept_fruit = _route_fruit
	for barrel in barrels:
		barrel.accept_batch = still.start_distilling
	still.bottle_collected.connect(_on_bottle_collected)
	pig_visit_timer.timeout.connect(_on_pig_visit_timeout)
	_schedule_pig_visit()
	squirrel_peek_timer.timeout.connect(_on_squirrel_peek_timeout)
	_schedule_squirrel_peek()
	fox_visit_timer.timeout.connect(_on_fox_visit_timeout)
	_schedule_fox_visit()
	hedgehog_visit_timer.timeout.connect(_on_hedgehog_visit_timeout)
	_schedule_hedgehog_visit()

func _schedule_pig_visit() -> void:
	pig_visit_timer.start(randf_range(pig_visit_min, pig_visit_max))

func _on_pig_visit_timeout() -> void:
	var fallen_fruits: Array = []
	for tree in trees:
		fallen_fruits.append_array(tree.get_fallen_fruits())
	if pig_scene != null and not fallen_fruits.is_empty():
		var pig = pig_scene.instantiate()
		pig.position = pig_entrance.position
		add_child(pig)
		await pig.visit(fallen_fruits)
		pig.queue_free()
	_schedule_pig_visit()

func _schedule_squirrel_peek() -> void:
	squirrel_peek_timer.start(randf_range(9.0, 20.0))

func _on_squirrel_peek_timeout() -> void:
	var perch: Marker2D = trees.pick_random().get_node("SquirrelPerch")
	var hidden_position := perch.global_position + Vector2(0, 58)
	var peek_position := perch.global_position + Vector2(0, -14)
	squirrel.global_position = hidden_position
	squirrel.rotation_degrees = 0.0
	squirrel.show()

	var peek := create_tween().set_trans(Tween.TRANS_QUAD)
	peek.tween_property(squirrel, "global_position", peek_position, 0.28).set_ease(Tween.EASE_OUT)
	peek.tween_interval(0.3)
	peek.tween_property(squirrel, "rotation_degrees", randf_range(-7.0, 7.0), 0.24)
	peek.tween_interval(randf_range(0.45, 1.15))
	peek.tween_property(squirrel, "global_position", hidden_position, 0.24).set_ease(Tween.EASE_IN)
	await peek.finished
	squirrel.hide()
	_schedule_squirrel_peek()

func _schedule_fox_visit() -> void:
	fox_visit_timer.start(randf_range(22.0, 40.0))

func _on_fox_visit_timeout() -> void:
	var perches: Array[Marker2D] = []
	for barrel in barrels:
		perches.append(barrel.get_node("FoxPerch"))

	var fox = fox_scene.instantiate()
	fox.position = fox_entrance.position
	add_child(fox)
	var exit_x := get_viewport().get_visible_rect().end.x + 100.0
	await fox.cross_orchard(perches, fox_landing, exit_x, still.bottle_spawn_point, still.take_full_bottle)
	fox.queue_free()
	_schedule_fox_visit()

func _schedule_hedgehog_visit() -> void:
	hedgehog_visit_timer.start(randf_range(14.0, 28.0))

func _on_hedgehog_visit_timeout() -> void:
	var hedgehog = hedgehog_scene.instantiate()
	hedgehog.position = hedgehog_entrance.position
	add_child(hedgehog)
	var exit_x := get_viewport().get_visible_rect().end.x + 100.0
	var first_tree_x: float = trees.front().global_position.x - 150.0
	var last_tree_x: float = trees.back().global_position.x + 150.0
	await hedgehog.cross_orchard(first_tree_x, last_tree_x, exit_x)
	hedgehog.queue_free()
	_schedule_hedgehog_visit()

func _route_fruit(fruit_kind: StringName, fruit_texture: Texture2D) -> bool:
	for barrel in barrels:
		if barrel.add_fruit(fruit_kind, fruit_texture):
			return true
	return false

func _on_bottle_collected(fruit_kind: StringName) -> void:
	bottle_counts[fruit_kind] += 1
	bottle_counter_labels[fruit_kind].text = str(bottle_counts[fruit_kind])
