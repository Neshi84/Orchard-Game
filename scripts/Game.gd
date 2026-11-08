extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Expected children named exactly: Tree, PlumTree, Barrel, Still
## The notice board shows the running total for each bottle type.
## This is the ONLY script that lets the systems talk to each other --
## Tree, Barrel, and Still never reference each other directly.

@onready var tree = $Tree
@onready var plum_tree = $PlumTree
@onready var barrel = $Barrel
@onready var still = $Still
@onready var bottle_counter_labels: Dictionary[StringName, Label] = {
	&"apple": $UI/BottleNoticeBoard/AppleTotal/BottleCount,
	&"plum": $UI/BottleNoticeBoard/PlumTotal/BottleCount,
}

var bottle_counts: Dictionary[StringName, int] = {&"apple": 0, &"plum": 0}

func _ready() -> void:
	tree.accept_fruit = barrel.add_fruit
	plum_tree.accept_fruit = barrel.add_fruit
	barrel.accept_batch = still.start_distilling
	still.bottle_collected.connect(_on_bottle_collected)

func _on_bottle_collected(fruit_kind: StringName) -> void:
	bottle_counts[fruit_kind] += 1
	bottle_counter_labels[fruit_kind].text = str(bottle_counts[fruit_kind])
