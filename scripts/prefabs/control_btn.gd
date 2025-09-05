@tool
extends Panel

signal pressed

@export var txt: Texture
@onready var btn_texture = $texture


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			pressed.emit()


func _physics_process(delta: float) -> void:
	btn_texture.texture = txt
