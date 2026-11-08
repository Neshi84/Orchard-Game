extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Routes fruit to the barrels, keeps bottle totals, and schedules wildlife.

@export var pig_scene: PackedScene
@export var pig_visit_min: float = 18.0
@export var pig_visit_max: float = 34.0
@export var hedgehog_scene: PackedScene

@onready var trees: Array = [$Tree, $PlumTree, $PearTree]
@onready var barrels: Array = [$Barrel, $Barrel2, $Barrel3]
@onready var still = $Still
@onready var pig_entrance: Marker2D = $PigEntrance
@onready var pig_visit_timer: Timer = $PigVisitTimer
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

func _schedule_hedgehog_visit() -> void:
	hedgehog_visit_timer.start(randf_range(14.0, 28.0))

func _on_hedgehog_visit_timeout() -> void:
	var hedgehog = hedgehog_scene.instantiate()
	hedgehog.position = hedgehog_entrance.position
	add_child(hedgehog)
	var exit_x := get_viewport().get_visible_rect().end.x + 100.0
	await hedgehog.cross_orchard(exit_x)
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
