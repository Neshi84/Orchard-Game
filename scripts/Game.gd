extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Routes fruit to the barrels, keeps bottle totals, and schedules wildlife.

@export var pig_scene: PackedScene
@export var pig_visit_min: float = 18.0
@export var pig_visit_max: float = 34.0
@export var fox_scene: PackedScene
@export var hedgehog_scene: PackedScene

const MAX_ORDER_QUANTITY := 10

@onready var trees: Array = [$Tree, $PlumTree, $PearTree]
@onready var barrels: Array = [$Barrel, $Barrel2, $Barrel3]
@onready var still = $Still
@onready var robot_helper = $RobotHelper
@onready var bottle_crate = $BottleCrate
@onready var pig_entrance: Marker2D = $PigEntrance
@onready var pig_visit_timer: Timer = $PigVisitTimer
@onready var squirrel: Sprite2D = $Squirrel
@onready var squirrel_peek_timer: Timer = $SquirrelPeekTimer
@onready var fox_entrance: Marker2D = $FoxEntrance
@onready var fox_landing: Marker2D = $FoxLanding
@onready var fox_visit_timer: Timer = $FoxVisitTimer
@onready var hedgehog_entrance: Marker2D = $HedgehogEntrance
@onready var hedgehog_visit_timer: Timer = $HedgehogVisitTimer
@onready var gold_count: Label = $UI/GoldNoticeBoard/Total/GoldCount
@onready var order_progress_labels: Dictionary[StringName, Label] = {
	&"apple": $UI/OrderScroll/Contents/Progress/Apple/Count,
	&"plum": $UI/OrderScroll/Contents/Progress/Plum/Count,
	&"pear": $UI/OrderScroll/Contents/Progress/Pear/Count,
}
@onready var order_status: Label = $UI/OrderScroll/Contents/Status
@onready var ship_button: Button = $UI/OrderScroll/Contents/ShipButton

var bottle_counts: Dictionary[StringName, int] = {&"apple": 0, &"plum": 0, &"pear": 0}
var order_requirements: Dictionary[StringName, int] = {}
var gold := 0:
	set(value):
		gold = value
		if is_node_ready():
			gold_count.text = str(gold)
			still.set_available_coins(gold)

func _ready() -> void:
	for tree in trees:
		tree.accept_fruit = _route_fruit
	for barrel in barrels:
		barrel.accept_batch = still.start_distilling
	robot_helper.find_fruit = _find_robot_fruit
	robot_helper.can_collect = _can_robot_collect
	still.bottle_crate = bottle_crate
	still.purchase_upgrade = _purchase_still_upgrade
	still.set_available_coins(gold)
	still.bottle_collected.connect(_on_bottle_collected)
	ship_button.pressed.connect(_ship_order)
	_roll_order()
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

func _can_robot_collect(fruit: Node2D) -> bool:
	if not is_instance_valid(fruit) or not fruit.is_on_ground():
		return false
	if robot_helper.selected_fruit != &"" and fruit.fruit_kind != robot_helper.selected_fruit:
		return false
	for barrel in barrels:
		if barrel.can_accept_fruit(fruit.fruit_kind):
			return true
	return false

func _find_robot_fruit(from_position: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for tree in trees:
		for fruit in tree.get_fallen_fruits():
			if not _can_robot_collect(fruit):
				continue
			var distance: float = from_position.distance_squared_to(fruit.global_position)
			if distance < nearest_distance:
				nearest = fruit
				nearest_distance = distance
	return nearest

func _on_bottle_collected(fruit_kind: StringName) -> void:
	bottle_counts[fruit_kind] += 1
	_update_order()

func _roll_order() -> void:
	var total := 0
	while total == 0:
		for fruit_kind in bottle_counts:
			var quantity := randi_range(0, MAX_ORDER_QUANTITY)
			order_requirements[fruit_kind] = quantity
			total += quantity
	_update_order()

func _update_order() -> void:
	for fruit_kind in order_requirements:
		order_progress_labels[fruit_kind].text = "%s   %d / %d" % [
			str(fruit_kind).capitalize(), bottle_counts[fruit_kind], order_requirements[fruit_kind]
		]
	ship_button.disabled = not _can_ship_order()
	order_status.text = "Collect the bottles" if ship_button.disabled else "Ready to ship"

func _can_ship_order() -> bool:
	for fruit_kind in order_requirements:
		if bottle_counts[fruit_kind] < order_requirements[fruit_kind]:
			return false
	return true

func _ship_order() -> void:
	if not _can_ship_order():
		return
	bottle_crate.clear_bottles()
	for fruit_kind in bottle_counts:
		gold += bottle_counts[fruit_kind]
		bottle_counts[fruit_kind] = 0
	gold_count.text = str(gold)
	_roll_order()
	order_status.text = "Order shipped!"

func _purchase_still_upgrade(cost: int) -> bool:
	if gold < cost:
		return false
	gold -= cost
	return true
