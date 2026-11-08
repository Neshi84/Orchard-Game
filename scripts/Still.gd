extends Node2D

signal started_distilling
signal finished_distilling(bottle_count)
signal bottle_collected(fruit_kind: StringName)

enum State { IDLE, DISTILLING, WAITING_FOR_PICKUP }

@export var bottle_scene: PackedScene
@export var plum_bottle_scene: PackedScene
@export var pear_bottle_scene: PackedScene
@export var distill_time: float = 6.0
@export var fruits_per_bottle: int = 5

var state: State = State.IDLE
var _batch_size: int
var _bottles_remaining: int
var _fill_duration: float
var _batch_bottle_scene: PackedScene

@onready var furnace_fire: AnimatedSprite2D = $FurnaceFire
@onready var gauge: AnimatedSprite2D = $Gauge
@onready var bottle_spawn_point: Marker2D = $BottleSpawnPoint
@onready var stream: ColorRect = $PourStream
@onready var steam_jets: Array[CPUParticles2D] = [$BoilerJointSteam, $CondenserJointSteam]

func start_distilling(fruit_amount: int, fruit_kind: StringName = &"apple") -> bool:
    if state != State.IDLE:
        return false
    match fruit_kind:
        &"apple":
            _batch_bottle_scene = bottle_scene
        &"plum":
            _batch_bottle_scene = plum_bottle_scene
        &"pear":
            _batch_bottle_scene = pear_bottle_scene
        _:
            return false
    if _batch_bottle_scene == null:
        return false

    _batch_size = maxi(1, floori(float(fruit_amount) / maxi(fruits_per_bottle, 1)))
    _bottles_remaining = _batch_size
    _fill_duration = maxf(distill_time, 0.0) / _batch_size
    _fill_next_bottle(fruit_kind)
    started_distilling.emit()
    return true

func _fill_next_bottle(fruit_kind: StringName) -> void:
    state = State.DISTILLING
    var bottle = _batch_bottle_scene.instantiate()
    bottle_spawn_point.add_child(bottle)
    bottle.collected.connect(_on_bottle_collected.bind(fruit_kind))
    stream.offset_bottom = to_local(bottle.mouth.global_position).y
    _start_effects()

    var fill := create_tween()
    fill.tween_method(bottle.set_fill_level, 0.0, 1.0, _fill_duration)
    await fill.finished

    _stop_effects()
    _bottles_remaining -= 1
    state = State.WAITING_FOR_PICKUP
    bottle.mark_full()
    if _bottles_remaining == 0:
        finished_distilling.emit(_batch_size)

func _start_effects() -> void:
    gauge.play("default")
    furnace_fire.show()
    furnace_fire.play("default")
    stream.show()
    for jet in steam_jets:
        jet.show()
        jet.restart()

func _stop_effects() -> void:
    stream.hide()
    furnace_fire.stop()
    furnace_fire.frame = 0
    furnace_fire.hide()
    gauge.stop()
    gauge.frame = 0
    for jet in steam_jets:
        jet.emitting = false
        jet.hide()

func _on_bottle_collected(fruit_kind: StringName) -> void:
    if _bottles_remaining > 0:
        _fill_next_bottle(fruit_kind)
    else:
        state = State.IDLE
    bottle_collected.emit(fruit_kind)
