extends Node3D

@export var icon:Texture
var usable: bool = true

func use() -> void:
	var player = find_parent("player")
	if player:
		find_parent("player").toggle_light()
