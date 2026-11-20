extends Panel

const LABEL_TEXTURE = preload("res://assets/fruit_label_parchment.png")

const FRUIT_TEXTURES := {
	&"apple": preload("res://assets/apple.png"),
	&"plum": preload("res://assets/plum.png"),
	&"pear": preload("res://assets/pear.png"),
}

var _icon: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var paper := StyleBoxTexture.new()
	paper.texture = LABEL_TEXTURE
	add_theme_stylebox_override("panel", paper)
	_icon = TextureRect.new()
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.anchor_left = 0.2
	_icon.anchor_top = 0.22
	_icon.anchor_right = 0.8
	_icon.anchor_bottom = 0.81
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

func set_fruit(kind: StringName) -> void:
	_icon.texture = FRUIT_TEXTURES.get(kind)
	visible = _icon.texture != null
