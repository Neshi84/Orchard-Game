extends Node2D

## Attach this to your root scene (e.g. Main.tscn).
## Expected children named exactly: Tree, Barrel, Still
## Optional: a UI/BottleCounterLabel Label node to show the running total.
## This is the ONLY script that lets the systems talk to each other --
## Tree, Barrel, and Still never reference each other directly.

@onready var tree: Node2D = $Tree
@onready var barrel = $Barrel
@onready var still = $Still
@onready var bottle_counter_label: Label = get_node_or_null("UI/BottleCounterLabel")

var bottle_count: int = 0

func _ready() -> void:
	tree.fruit_collected.connect(_on_fruit_collected)
	barrel.emptied.connect(_on_barrel_emptied)
	still.bottle_collected.connect(_on_bottle_collected)
	_update_bottle_label()

func _on_fruit_collected(_fruit) -> void:
	var accepted: bool = barrel.add_fruit()
	if not accepted:
		# Barrel was full/fermenting when this fruit got clicked.
		# The fruit already played its "collected" pop animation and is gone,
		# so as a beginner-friendly choice we just don't add it.
		# (Later you could disable clicking fruit while the barrel is full instead.)
		pass

func _on_barrel_emptied(amount: int) -> void:
	still.start_distilling(amount)

func _on_bottle_collected() -> void:
	bottle_count += 1
	_update_bottle_label()

func _update_bottle_label() -> void:
	if bottle_counter_label:
		bottle_counter_label.text = "Bottles: %d" % bottle_count
