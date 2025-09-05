extends Node3D

@export var code: String = ""

func open() -> void:
	$AnimationPlayer.play("door_open")
	var tm = get_tree().create_timer(2).timeout
	await tm
	$AnimationPlayer.play("close_door")
