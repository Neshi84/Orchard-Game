extends Node2D

signal started_distilling
signal finished_distilling(bottle_count)
signal bottle_collected(fruit_kind: StringName)

enum State { IDLE, DISTILLING, WAITING_FOR_PICKUP }

const MAX_BOILERS := 4
const UPGRADE_COSTS := [50, 100, 150]
const FruitLabel = preload("res://scripts/FruitLabel.gd")

@export var bottle_scene: PackedScene
@export var plum_bottle_scene: PackedScene
@export var pear_bottle_scene: PackedScene
@export var distill_time: float = 6.0
@export var bottle_fill_time: float = 0.6
@export var fruits_per_bottle: int = 5

var state: State = State.IDLE
var bottle_crate: Node2D
var boiler_count := 1
var _boilers: Array[Dictionary] = [{}, {}, {}, {}]
var purchase_upgrade: Callable
var available_coins := 0
var _bottling_queue: Array[int] = []
var _active_boiler := -1
var _batch_size: int
var _bottles_remaining: int
var _batch_bottle_scene: PackedScene
var _batch_fruit_kind: StringName
var _full_bottle: Area2D
var _boiler_art: Array[Node2D] = []
var _boiler_labels: Array[Panel] = []
var _upgrade_button: Button
var _boiler_cap: Sprite2D
var _extension_pipe: Line2D

@onready var furnace_fire: AnimatedSprite2D = $FurnaceFire
@onready var gauge: AnimatedSprite2D = $Gauge
@onready var bottle_spawn_point: Marker2D = $BottleSpawnPoint
@onready var stream: ColorRect = $PourStream
@onready var pour_sound: AudioStreamPlayer = $PourSound
@onready var bottle_pickup_sound: AudioStreamPlayer = $BottlePickupSound
@onready var steam_jets: Array[CPUParticles2D] = [$BoilerJointSteam, $CondenserJointSteam]

func _ready() -> void:
	_build_upgrade_controls()
	_update_boilers()

func _build_upgrade_controls() -> void:
	var artwork: Sprite2D = $Sprite2D
	var texture := artwork.texture
	# Keep the furnace and bottling bench fixed while the boiler grows upward.
	artwork.region_enabled = true
	artwork.region_rect = Rect2(0, 350, 1536, 674)
	artwork.position = Vector2(0, 52.5)
	var condenser_top := Sprite2D.new()
	condenser_top.texture = texture
	condenser_top.region_enabled = true
	condenser_top.region_rect = Rect2(710, 95, 826, 255)
	condenser_top.scale = Vector2(0.3, 0.3)
	condenser_top.position = Vector2(106.5, -86.85)
	add_child(condenser_top)
	_boiler_cap = Sprite2D.new()
	_boiler_cap.texture = texture
	_boiler_cap.region_enabled = true
	_boiler_cap.region_rect = Rect2(0, 95, 710, 255)
	_boiler_cap.scale = Vector2(0.3, 0.3)
	add_child(_boiler_cap)
	_extension_pipe = Line2D.new()
	_extension_pipe.width = 24.0
	_extension_pipe.joint_mode = Line2D.LINE_JOINT_ROUND
	_extension_pipe.default_color = Color(0.22, 0.12, 0.05)
	_extension_pipe.show_behind_parent = true
	add_child(_extension_pipe)
	var copper := Line2D.new()
	copper.width = 18.0
	copper.joint_mode = Line2D.LINE_JOINT_ROUND
	copper.default_color = Color(0.96, 0.48, 0.06)
	_extension_pipe.add_child(copper)
	var highlight := Line2D.new()
	highlight.position = Vector2(-2, -3)
	highlight.width = 4.0
	highlight.joint_mode = Line2D.LINE_JOINT_ROUND
	highlight.default_color = Color(1.0, 0.79, 0.35)
	_extension_pipe.add_child(highlight)
	for index in range(MAX_BOILERS):
		var label := FruitLabel.new()
		label.position = Vector2(-172, -27.483 - index * 81)
		label.size = Vector2(40, 36.966)
		label.z_index = 2
		add_child(label)
		_boiler_labels.append(label)
		if index == 0:
			continue
		var segment := Node2D.new()
		segment.position = Vector2(0, -index * 81)
		add_child(segment)
		var cylinder := Sprite2D.new()
		cylinder.texture = texture
		cylinder.region_enabled = true
		cylinder.region_rect = Rect2(0, 350, 710, 270)
		cylinder.scale = Vector2(0.3, 0.3)
		cylinder.position = Vector2(-123.9, -8.1)
		segment.add_child(cylinder)
		var dial := gauge.duplicate() as AnimatedSprite2D
		dial.name = "Gauge"
		segment.add_child(dial)
		_boiler_art.append(segment)
	_upgrade_button = Button.new()
	_upgrade_button.size = Vector2(136, 52)
	_upgrade_button.icon = preload("res://assets/gold_coin.svg")
	_upgrade_button.expand_icon = true
	_upgrade_button.add_theme_constant_override("icon_max_width", 22)
	_upgrade_button.add_theme_font_size_override("font_size", 19)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var paper := StyleBoxTexture.new()
		paper.texture = preload("res://assets/fruit_label_parchment.png")
		paper.content_margin_left = 16
		paper.content_margin_right = 16
		paper.content_margin_top = 10
		paper.content_margin_bottom = 10
		if style_name == "hover":
			paper.modulate_color = Color(1.1, 1.05, 0.9)
		elif style_name == "pressed":
			paper.modulate_color = Color(0.85, 0.75, 0.6)
		_upgrade_button.add_theme_stylebox_override(style_name, paper)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_upgrade_button.add_theme_color_override(color_name, Color("#543018"))
	_upgrade_button.pressed.connect(add_boiler)
	add_child(_upgrade_button)

func add_boiler() -> bool:
	if boiler_count >= MAX_BOILERS:
		return false
	var cost: int = UPGRADE_COSTS[boiler_count - 1]
	if not purchase_upgrade.is_valid() or not purchase_upgrade.call(cost):
		return false
	boiler_count += 1
	_update_boilers()
	return true

func set_available_coins(coins: int) -> void:
	available_coins = coins
	_update_boilers()

func start_distilling(fruit_amount: int, fruit_kind: StringName = &"apple") -> bool:
	var selected_scene: PackedScene
	match fruit_kind:
		&"apple":
			selected_scene = bottle_scene
		&"plum":
			selected_scene = plum_bottle_scene
		&"pear":
			selected_scene = pear_bottle_scene
	if selected_scene == null or fruit_amount <= 0:
		return false
	var slot := -1
	for index in range(boiler_count):
		if _boilers[index].is_empty():
			slot = index
			break
	if slot < 0:
		return false
	var quantity := maxi(1, floori(float(fruit_amount) / maxi(fruits_per_bottle, 1)))
	_boilers[slot] = {"fruit": fruit_kind, "scene": selected_scene, "quantity": quantity, "ready": false}
	if state == State.IDLE:
		state = State.DISTILLING
	_update_boilers()
	_distill_batch(slot)
	started_distilling.emit()
	return true

func _distill_batch(slot: int) -> void:
	await get_tree().create_timer(maxf(distill_time, 0.001)).timeout
	_boilers[slot]["ready"] = true
	_bottling_queue.append(slot)
	_update_boilers()
	_start_next_batch()

func _start_next_batch() -> void:
	if _active_boiler >= 0 or _bottling_queue.is_empty():
		return
	_active_boiler = _bottling_queue.pop_front()
	var batch := _boilers[_active_boiler]
	_batch_fruit_kind = batch["fruit"]
	_batch_bottle_scene = batch["scene"]
	_batch_size = batch["quantity"]
	_bottles_remaining = _batch_size
	_fill_next_bottle()

func _fill_next_bottle() -> void:
	state = State.DISTILLING
	var bottle = _batch_bottle_scene.instantiate()
	bottle.crate = bottle_crate
	bottle_spawn_point.add_child(bottle)
	var sprite: Sprite2D = bottle.sprite
	var sprite_bottom := sprite.transform * Vector2(0, sprite.get_rect().end.y)
	bottle.position.y = -sprite_bottom.y
	bottle.collected.connect(_on_bottle_collected)
	stream.offset_bottom = to_local(bottle.mouth.global_position).y
	stream.show()
	pour_sound.play()
	steam_jets[1].show()
	steam_jets[1].restart()
	_update_boilers()
	var fill := create_tween()
	fill.tween_method(bottle.set_fill_level, 0.0, 1.0, maxf(bottle_fill_time, 0.001))
	await fill.finished
	stream.hide()
	pour_sound.stop()
	steam_jets[1].emitting = false
	steam_jets[1].hide()
	_bottles_remaining -= 1
	state = State.WAITING_FOR_PICKUP
	_full_bottle = bottle
	bottle.mark_full()
	_update_boilers()
	if _bottles_remaining == 0:
		finished_distilling.emit(_batch_size)

func _update_boilers() -> void:
	_upgrade_button.visible = boiler_count < MAX_BOILERS and available_coins >= UPGRADE_COSTS[boiler_count - 1]
	if boiler_count < MAX_BOILERS:
		_upgrade_button.text = "+ %d" % UPGRADE_COSTS[boiler_count - 1]
		_upgrade_button.tooltip_text = "Add a boiler segment for %d coins" % UPGRADE_COSTS[boiler_count - 1]
	var rise := (boiler_count - 1) * 81.0
	_boiler_cap.position = Vector2(-123.9, -86.85 - rise)
	_upgrade_button.position = Vector2(-300, -146 - rise)
	_extension_pipe.points = PackedVector2Array([Vector2(-121.5, -123 - rise), Vector2(-121.5, -141 - rise), Vector2(43.5, -141 - rise), Vector2(43.5, -124.2)])
	for lining in _extension_pipe.get_children():
		lining.points = _extension_pipe.points
	_extension_pipe.visible = true
	steam_jets[0].position.y = -123.0 - rise
	var any_heating := false
	for index in range(MAX_BOILERS):
		var batch := _boilers[index]
		var heating: bool = not batch.is_empty() and not batch["ready"]
		var status := "Empty"
		if not batch.is_empty():
			status = "%s · Distilling" % str(batch["fruit"]).capitalize()
			if batch["ready"]:
				status = "%s · Queued" % str(batch["fruit"]).capitalize()
			if index == _active_boiler:
				status = "Collect bottle" if state == State.WAITING_FOR_PICKUP else "Bottling"
		_boiler_labels[index].set_fruit(batch.get("fruit", &""))
		_boiler_labels[index].tooltip_text = status
		_boiler_labels[index].visible = index < boiler_count and not batch.is_empty()
		var dial := gauge
		any_heating = any_heating or heating
		if index > 0:
			_boiler_art[index - 1].visible = index < boiler_count
			dial = _boiler_art[index - 1].get_node("Gauge")
		if heating:
			dial.play()
		else:
			dial.stop()
			dial.frame = 0
	furnace_fire.visible = any_heating
	if any_heating:
		furnace_fire.play()
	else:
		furnace_fire.stop()
		furnace_fire.frame = 0
	if any_heating:
		steam_jets[0].show()
		steam_jets[0].emitting = true
	else:
		steam_jets[0].hide()
		steam_jets[0].emitting = false

func take_full_bottle(carrier: Node2D) -> Area2D:
	if state != State.WAITING_FOR_PICKUP:
		return null
	var bottle := _full_bottle
	bottle.input_pickable = false
	bottle.reparent(carrier, false)
	_advance_batch()
	return bottle

func _on_bottle_collected() -> void:
	var fruit_kind := _batch_fruit_kind
	bottle_pickup_sound.play()
	_advance_batch()
	bottle_collected.emit(fruit_kind)

func _advance_batch() -> void:
	_full_bottle = null
	if _bottles_remaining > 0:
		_fill_next_bottle()
		return
	_boilers[_active_boiler] = {}
	_active_boiler = -1
	state = State.IDLE
	for batch in _boilers:
		if not batch.is_empty():
			state = State.DISTILLING
			break
	_update_boilers()
	_start_next_batch()
