@tool
extends Panel

@export_range(0.0, 1.0) var _transparency: float = 1.0
@export_range(0.0, 1.0) var dimensions: float = 0.5
@export var txt: Texture
@export var input_code: String
@onready var btn_texture = $btn_texture

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if input_code:
			if Input.is_action_pressed(input_code):
				Input.action_release(input_code)
			else:
				Input.action_press(input_code)

func _physics_process(_delta: float) -> void:
	self.modulate.a = _transparency
	btn_texture.texture = txt
	scale = Vector2(dimensions, dimensions)
