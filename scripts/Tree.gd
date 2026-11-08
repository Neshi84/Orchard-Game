extends Node2D

## Node hierarchy expected:
##   Tree (Node2D)
##   ├── Sprite2D              (the tree trunk/canopy art)
##   └── SpawnPoints (Node2D)  -- container
##       ├── Marker2D          -- one per spot fruit can grow, place among branches
##       ├── Marker2D
##       └── ...

signal fruit_collected(fruit)

@export var fruit_scene: PackedScene
@export var max_fruits: int = 5
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0

var active_fruits: Array = []
var spawn_points: Array = []
var accept_fruit: Callable

func _ready() -> void:
	if has_node("SpawnPoints"):
		spawn_points = get_node("SpawnPoints").get_children()
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	var wait_time := randf_range(spawn_interval_min, spawn_interval_max)
	await get_tree().create_timer(wait_time).timeout
	_try_spawn_fruit()
	_schedule_next_spawn()

func _try_spawn_fruit() -> void:
	if not fruit_scene or spawn_points.is_empty():
		return
	if active_fruits.size() >= max_fruits:
		return

	var free_points: Array = spawn_points.filter(func(p): return not p.has_meta("occupied"))
	if free_points.is_empty():
		return

	var point = free_points[randi() % free_points.size()]
	point.set_meta("occupied", true)

	var fruit = fruit_scene.instantiate()
	fruit.accept_collection = accept_fruit
	add_child(fruit)
	fruit.global_position = point.global_position
	fruit.spawn_point = point
	active_fruits.append(fruit)

	fruit.fell.connect(_on_fruit_fell.bind(fruit))
	fruit.rotted_away.connect(_on_fruit_gone.bind(fruit))
	fruit.eaten.connect(_on_fruit_gone.bind(fruit))
	fruit.collected.connect(_on_fruit_collected)

func get_fallen_fruits() -> Array:
	return active_fruits.filter(func(fruit): return fruit.is_on_ground())

func _on_fruit_fell(fruit) -> void:
	# free up the branch spot as soon as the fruit hits the ground,
	# so the tree can start growing a new one while the old one sits below it
	if fruit.spawn_point:
		fruit.spawn_point.remove_meta("occupied")

func _on_fruit_gone(fruit) -> void:
	active_fruits.erase(fruit)

func _on_fruit_collected(fruit) -> void:
	_on_fruit_gone(fruit)
	fruit_collected.emit(fruit)
