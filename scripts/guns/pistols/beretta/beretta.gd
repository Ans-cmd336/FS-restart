extends Node3D

@onready var fire_sfx: AudioStreamPlayer3D = $fire_sfx
@onready var muzzle_flash: GPUParticles3D = $MuzzleFlash/GPUParticles3D
@onready var fire_pos: Marker3D = $fire_pos
@onready var gun_anim: AnimationPlayer = $gun_anim

var type: String = "pistol"
var max_ammo: int = 24
var current_ammo: int = 2
var ammo: int = 10
var idle_fire_anim: String = "pistol_idle"
var walk_fire_anim: String = "pistol_walk"
var crouch_fire_anim: String = "pistol_crouch"

var avatar_reload_anim: String = "pistol_fire"

func fire() -> void:
	if current_ammo == 1:
		gun_anim.play("last_fire")
	else:
		gun_anim.play("fire")
	muzzle_flash.emitting = true

func reload_gun(reload: bool) -> void:
	if reload:
		gun_anim.play("reload")
		await gun_anim.animation_finished
		if get_parent().name == "hand":
			if (ammo - max_ammo) > 0:
				current_ammo = max_ammo
				ammo -= max_ammo
			else:
				current_ammo = ammo
				ammo = 0
	else:
		gun_anim.stop()
