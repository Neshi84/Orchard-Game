extends Node2D

var _next_slot := 0

@onready var slots: Node2D = $Slots
@onready var in_transit: Node2D = $InTransit

func reserve_slot(bottle: Node2D) -> Marker2D:
	var slot := slots.get_child(_next_slot) as Marker2D
	_next_slot = (_next_slot + 1) % slots.get_child_count()
	bottle.reparent(in_transit)
	return slot

func store_bottle(bottle: Node2D, slot: Marker2D) -> void:
	for previous in slot.get_children():
		previous.hide()
		previous.queue_free()
	bottle.reparent(slot)
	bottle.z_index = 0

func clear_bottles() -> void:
	_clear_container(in_transit)
	for slot in slots.get_children():
		_clear_container(slot)
	_next_slot = 0

func _clear_container(container: Node) -> void:
	for bottle in container.get_children():
		container.remove_child(bottle)
		bottle.queue_free()
