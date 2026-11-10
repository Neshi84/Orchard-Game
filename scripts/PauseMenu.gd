extends ColorRect

@onready var resume_button: Button = $Board/Buttons/Resume
@onready var quit_button: Button = $Board/Buttons/Quit

func _ready() -> void:
	resume_button.pressed.connect(_set_open.bind(false))
	quit_button.pressed.connect(get_tree().quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_set_open(not visible)

func _set_open(open: bool) -> void:
	get_tree().paused = open
	visible = open
	if open:
		resume_button.grab_focus()
