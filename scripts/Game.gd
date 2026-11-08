extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Expected children named exactly: Tree, PlumTree, Barrel, Still
## The notice board's BottleCount label shows the running total.
## This is the ONLY script that lets the systems talk to each other --
## Tree, Barrel, and Still never reference each other directly.

@onready var tree = $Tree
@onready var plum_tree = $PlumTree
@onready var barrel = $Barrel
@onready var still = $Still
@onready var bottle_counter_label: Label = get_node_or_null("UI/BottleNoticeBoard/BottleTotal/BottleCount")

var bottle_count: int = 0

func _ready() -> void:
	tree.accept_fruit = barrel.add_fruit
	plum_tree.accept_fruit = barrel.add_fruit
	barrel.accept_batch = still.start_distilling
	still.bottle_collected.connect(_on_bottle_collected)
	_update_bottle_label()

func _on_bottle_collected() -> void:
	bottle_count += 1
	_update_bottle_label()

func _update_bottle_label() -> void:
	if bottle_counter_label:
		bottle_counter_label.text = str(bottle_count)
