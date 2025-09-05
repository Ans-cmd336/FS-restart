extends RigidBody3D

func _ready() -> void:
	top_level = true

func _physics_process(delta: float) -> void:
	apply_impulse(-transform.basis.z * 0.005, -transform.basis.z)

func _on_body_entered(body: Node) -> void:
	if !body.is_in_group("npc"):
		if body is CharacterBody3D:
			body.take_dam(50)
	queue_free()
