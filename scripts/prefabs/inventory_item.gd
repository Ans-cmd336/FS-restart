extends Control

var can_drag: bool = false
var rest_pos:Vector2 = Vector2.ZERO
var picked_item: Node3D
var pressed_once:bool = false

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			can_drag = true
			rest_pos = position
		else:
			if global_position.x < find_parent("inventory").global_position.x:
				if picked_item:
					picked_item.show()
					find_parent("player").drop_item_from_inventory(picked_item)
				queue_free()
			else:
				can_drag = false
				position = rest_pos
	if event is InputEventMouseMotion:
		if can_drag:
			global_position = get_global_mouse_position()


func _on_button_pressed() -> void:
	if !pressed_once:
		pressed_once = true
		var tm = get_tree().create_timer(1).timeout
		await tm
		pressed_once = false
	else:
		if picked_item.usable:
			picked_item.use()
	
