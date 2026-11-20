extends Node2D

signal grip_closed

@onready var player: AnimationPlayer = $AnimationPlayer
@onready var steam: CPUParticles2D = $Chassis/Chimney/SteamOutlet/BoilerSteam

var _steam_burst: CPUParticles2D
var _idle_delay := 0.0

func _ready() -> void:
	_idle_delay = randf_range(2.5, 5.0)
	_steam_burst = steam.duplicate()
	_steam_burst.name = "IdleSteamBurst"
	_steam_burst.emitting = false
	_steam_burst.one_shot = true
	_steam_burst.preprocess = 0.0
	_steam_burst.explosiveness = 0.85
	_steam_burst.amount = 12
	_steam_burst.lifetime = 0.7
	_steam_burst.initial_velocity_min = 25.0
	_steam_burst.initial_velocity_max = 40.0
	steam.get_parent().add_child(_steam_burst)

func idle(delta: float) -> void:
	if player.current_animation != &"idle":
		player.play(&"idle", 0.12)
		_idle_delay = randf_range(2.5, 5.0)
	_idle_delay -= delta
	if _idle_delay <= 0.0:
		_idle_delay = randf_range(3.0, 6.0)
		_steam_burst.restart()

func walk(rate: float) -> void:
	if player.current_animation != &"walk" or not is_equal_approx(player.get_playing_speed(), rate):
		player.play(&"walk", 0.09, rate, rate < 0.0)

func pick_up() -> void:
	player.play(&"pickup", 0.09)

# Called by the pickup clip on the frame the leading claw closes.
func close_grip() -> void:
	grip_closed.emit()
