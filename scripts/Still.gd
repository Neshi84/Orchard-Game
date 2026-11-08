extends Node2D

## Node hierarchy expected:
##   Still (Node2D)
##   ├── Sprite2D
##   └── BottleSpawnPoint (Marker2D)   -- where bottles pop out from

signal started_distilling
signal finished_distilling(bottle_count)
signal bottle_collected

enum State { IDLE, DISTILLING }
@onready var furnace_fire: AnimatedSprite2D = $FurnaceFire
@export var bottle_scene: PackedScene
@export var distill_time: float = 6.0
@export var fruits_per_bottle: int = 5
@export var pulse_scale: float = 1.05
@export var pulse_speed: float = 0.4

var state: State = State.IDLE

@onready var gauge: AnimatedSprite2D = $Gauge
@onready var sprite: Sprite2D = $Sprite2D
@onready var bottle_spawn_point: Node2D = get_node_or_null("BottleSpawnPoint")
@onready var steam_jets: Array[CPUParticles2D] = [$BoilerJointSteam, $CondenserJointSteam]

## Call this from Game.gd when the Barrel empties into the still.
func start_distilling(fruit_amount: int) -> bool:
    if state != State.IDLE:
        return false

    state = State.DISTILLING
    started_distilling.emit()
    
    gauge.play("default")
    # Start furnace fire
    furnace_fire.visible = true
    furnace_fire.play("default")
    for jet in steam_jets:
        jet.show()
        jet.restart()

    var bottle_count := int(fruit_amount / float(fruits_per_bottle))

    #_pulse_loop()

    await get_tree().create_timer(distill_time).timeout

    # Stop furnace fire
    furnace_fire.stop()
    furnace_fire.frame = 0
    furnace_fire.visible = false
    for jet in steam_jets:
        jet.emitting = false
        jet.hide()
    gauge.stop()
    gauge.frame = 0
    _finish_distilling(bottle_count)

    return true

func _pulse_loop() -> void:
    while state == State.DISTILLING:
        var tween := create_tween()
        tween.tween_property(sprite, "scale", Vector2.ONE * pulse_scale, pulse_speed)
        tween.tween_property(sprite, "scale", Vector2.ONE, pulse_speed)
        await tween.finished

func _finish_distilling(bottle_count: int) -> void:
    state = State.IDLE
    #sprite.scale = Vector2.ONE
    for i in range(max(bottle_count, 1)):
        _spawn_bottle(i)
    finished_distilling.emit(bottle_count)

func _spawn_bottle(index: int) -> void:
    if not bottle_scene:
        return
    var bottle = bottle_scene.instantiate()
    get_tree().current_scene.add_child(bottle)
    var base_pos := bottle_spawn_point.global_position if bottle_spawn_point else global_position
    bottle.global_position = base_pos + Vector2(index * 20 - 20, -10)
    bottle.collected.connect(_on_bottle_collected)
    if bottle.has_method("pop_out"):
        bottle.pop_out()

func _on_bottle_collected() -> void:
    bottle_collected.emit()
