extends CharacterBody3D
#region var
@export var idol_gate:Node3D
#ui
@onready var player_ui: CanvasLayer = $ui
@onready var health_bar:TextureProgressBar = $ui/bars/health_bar
@onready var strength_bar:TextureProgressBar = $ui/bars/strength_bar
@onready var ammo_txt: Label = $ui/Label
@onready var tips_txt: Label = $ui/tips_txt

#camera var
@onready var camera: Camera3D = $fpp_cam/Camera3D
@onready var fpp_cam: Node3D = $fpp_cam

@onready var hand: Node3D = $swat/Armature/Skeleton3D/gun_pos/hand
@onready var mesh: Node3D = $SubViewportContainer/SubViewport/view_model_cam/mesh
@onready var shoulder_l: Node3D = $swat/Armature/Skeleton3D/back/shoulder_1
@onready var shoulder_r: Node3D = $swat/Armature/Skeleton3D/back/shoulder_2
@onready var leg: Node3D = $swat/Armature/Skeleton3D/legBone/leg

#collision shapes
@onready var stand_coll: CollisionShape3D = $stand_coll
@onready var crouch_coll: CollisionShape3D = $crouch_coll

#raycasts
@onready var state_ray: RayCast3D = $state_ray
@onready var interaction_ray: RayCast3D = $fpp_cam/Camera3D/interaction_ray
@onready var fire_ray: RayCast3D = $fpp_cam/Camera3D/fire_ray

#item and inventory
@onready var drop_pos: Node3D = $drop_pos
@onready var inventory: Control = $ui/inventory
@onready var inventory_grid: GridContainer = $ui/inventory/back/margin/GridContainer

@onready var bullet = preload("res://scenes/bullet.tscn")
@onready var inventory_slot = preload("res://scenes/prefabs/ui/inventory_item.tscn")

var health: int = 100
var strength: int = 100

#puzzles and obstacles
var cards: Array
var frame_pieces: Array = ["01","04"]
var idols: int = 0
var has_ammunition: bool = false

#state variables
var crouched: bool = false
var sprinting: bool = false
var reloading: bool = false
var ads: bool = false

#speed var
var speed: float = 2.0
const WALK_SPEED: float = 2.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.8
const crouch_speed: float = 0.8

#sensitivity
const SENSITIVITY: float = 0.004

var gravity: float = 9.8
#endregion

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if get_parent().name == "world" and !inventory.visible:
		if event is InputEventMouseMotion:
			rotate_y(-event.screen_relative.x * SENSITIVITY)
			fpp_cam.rotate_x(-event.screen_relative.y * SENSITIVITY)
			fpp_cam.rotation.x = clamp(fpp_cam.rotation.x, -1.25,1.5)

func _physics_process(delta: float) -> void:
	$SubViewportContainer/SubViewport/view_model_cam.global_transform = $fpp_cam.global_transform
	$SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
	mesh.global_transform = $SubViewportContainer/SubViewport/view_model_cam.global_transform
	$ui/fps.text = str(Engine.get_frames_per_second())
	health_and_strength()
	toggle_inventory()
	if get_parent().name == "world":
		die()
		basic_movement(delta)
		jump_and_gravity(delta)
		crouch(delta)
		sprint()
		interact_with_obj_and_npcs()
		#pick_and_drop_gun()
		#switch_gun()
		move_and_slide()

func take_damage(damage: int) -> void:
	health -= damage
	health_bar.value = health

func die() -> void:
	if health <= 0:
		print("u r dead")

func basic_movement(delta: float) -> void:
	if sprinting:
		speed = SPRINT_SPEED
	elif crouched:
		speed = crouch_speed
	else:
		speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)

func jump_and_gravity(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			if crouched:
				pass
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta

func crouch(delta_val: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("crouch"):
			crouched = !crouched
	
		if crouched:
			if sprinting:
				sprinting = false
				Input.action_release("forward")
			stand_coll.disabled = true
			crouch_coll.disabled = false
			fpp_cam.position.y = lerp(fpp_cam.position.y,0.992, delta_val * 20)
			fpp_cam.rotation.x = clamp(fpp_cam.rotation.x, deg_to_rad(-60), deg_to_rad(40))
		elif !state_ray.is_colliding():
			stand_coll.disabled = false
			crouch_coll.disabled = true
			fpp_cam.position.y = lerp(fpp_cam.position.y, 1.462, delta_val * 20)

func sprint() -> void:
	if is_on_floor():
		if Input.is_action_pressed("sprint"):
			sprinting = true
			if crouched:
				crouched = false
		else:
			sprinting = false

func interact_with_obj_and_npcs() -> void:
	if interaction_ray.is_colliding() and interaction_ray.get_collider():
		if interaction_ray.get_collider().is_in_group("npc"):
			tips_txt.text = "talk - I"
			if Input.is_action_just_pressed("interact"):
				interaction_ray.get_collider().anim_player.play("talk")
		elif interaction_ray.get_collider().is_in_group("pickable"):
			if Input.is_action_just_pressed("interact"):
				var slot_inst = inventory_slot.instantiate()
				slot_inst.find_child("icon").texture = interaction_ray.get_collider().get_parent().icon
				slot_inst.picked_item = interaction_ray.get_collider().get_parent()
				inventory_grid.add_child(slot_inst)
				interaction_ray.get_collider().get_parent().hide()
				interaction_ray.get_collider().get_parent().reparent(self, false)
		elif interaction_ray.get_collider().is_in_group("vehicle"):
			if !Missions.one:
				if Input.is_action_just_pressed("interact"):
					interaction_ray.get_collider().find_child("Virtual_joystick").show()
					interaction_ray.get_collider().is_active = true
					self.reparent(interaction_ray.get_collider(), false)
					stand_coll.disabled = true
					crouch_coll.disabled = true
					self.global_position = interaction_ray.get_collider().sit_pos.global_position
					self.global_rotation.y = interaction_ray.get_collider().sit_pos.global_rotation.y
					velocity = Vector3.ZERO
		if Input.is_action_just_pressed("interact"):
			match interaction_ray.get_collider().name:
				"ammunition":
					interaction_ray.get_collider().get_parent().queue_free()
					has_ammunition = true
				"idol":
					idols = 3
					interaction_ray.get_collider().get_parent().queue_free()
				"idol_board":
					if idols > 0:
						if !interaction_ray.get_collider().get_parent().find_child("idol").visible:
							if idols == 1:
								idol_gate.find_child("anim").play("open")
							interaction_ray.get_collider().get_parent().find_child("idol").show()
							idols -= 1
						else:
							showmessege("already occupied...")
					else:
						showmessege("insufficient item...")
				"Frame":
					for piece in frame_pieces:
						if interaction_ray.get_collider().get_parent().find_child(piece):
							interaction_ray.get_collider().get_parent().find_child(piece).show()
				"FramePiece":
					frame_pieces.append(interaction_ray.get_collider().get_parent().id)
					interaction_ray.get_collider().get_parent().queue_free()
				"door_card":
					cards.append(interaction_ray.get_collider().get_parent().card_code)
					var slot_inst = inventory_slot.instantiate()
					slot_inst.find_child("icon").texture = interaction_ray.get_collider().get_parent().icon
					slot_inst.picked_item = interaction_ray.get_collider().get_parent()
					inventory_grid.add_child(slot_inst)
					interaction_ray.get_collider().get_parent().hide()
					interaction_ray.get_collider().get_parent().reparent(self, false)
				"card_door":
					if cards.has(interaction_ray.get_collider().get_parent().code):
						interaction_ray.get_collider().get_parent().open()
						cards.erase(interaction_ray.get_collider().get_parent().code)
					else:
						tips_txt.text = "Need Entry pass to open"
	else:
		tips_txt.text = ""

func pick_and_drop_gun() -> void:
	if Input.is_action_just_pressed("drop_gun") and interaction_ray.is_colliding() and interaction_ray.get_collider():
			if interaction_ray.get_collider().is_in_group("gun"):
				if interaction_ray.get_collider().get_parent().type == "pistol":
					if leg.get_child_count() != 0:
						drop_gun_from(leg)
					if hand.get_child_count() != 0:
						if hand.get_child(0).type == "pistol":
							drop_gun_from(hand)
							move_gun_to(hand)
						else:
							move_gun_to(leg)
					else:
						move_gun_to(hand)
				else:
					if hand.get_child_count() == 0:
						if shoulder_r.get_child_count() == 0 or shoulder_l.get_child_count() == 0:
							move_gun_to(hand)
							if !shoulder_l.get_child(0):
								hand.get_child(0).type = "prim"
							else:
								hand.get_child(0).type = "sec"
						else:
							drop_gun_from(shoulder_r)
							move_gun_to(shoulder_r)
							shoulder_r.get_child(0).type = "sec"
					else:
						if shoulder_r.get_child_count() == 0 and shoulder_l.get_child_count() == 0:
							if hand.get_child(0).type == "pistol":
								move_gun_to(shoulder_l)
								shoulder_l.get_child(0).type = "prim"
							else:
								move_gun_to(shoulder_r)
								shoulder_r.get_child(0).type = "sec"
						else:
							if shoulder_r.get_child_count() != 0:
								drop_gun_from(shoulder_r)
							move_gun_to(shoulder_r)
							shoulder_r.get_child(0).type = "sec"
	if hand.get_child_count() != 0:
		ammo_txt.text = str(hand.get_child(0).current_ammo, "/", hand.get_child(0).ammo)
		reload(hand.get_child(0))
		if Input.is_action_pressed("shoot"):
			shoot(hand.get_child(0))
	else:
			ammo_txt.text = str("")

func move_gun_to(a:Node3D) -> void:
	interaction_ray.get_collider().get_parent().reparent(a)
	a.get_child(0).transform = Transform3D(Vector3(1.0,0.0,0.0),Vector3(0.0,1.0,0.0),Vector3(0.0,0.0,1.0),Vector3.ZERO)

func drop_gun_from(a:Node3D) -> void:
	if a.get_child(0).type != "pistol":
		a.get_child(0).type = ""
	a.get_child(0).global_rotation = Vector3(deg_to_rad(85),0,0)
	a.get_child(0).global_position = drop_pos.global_position
	a.get_child(0).reparent(get_parent())

func switch_gun() -> void:
	if Input.is_action_just_pressed("prim"):
		switch(shoulder_l)
	if Input.is_action_just_pressed("sec"):
		switch(shoulder_r)
	if Input.is_action_just_pressed("pistol"):
		switch(leg)
	if Input.is_action_just_pressed("melee"):
		switch(hand,true)

func switch(a:Node3D,melee:bool=false) -> void:
	if a.get_child(0):
		if hand.get_child_count() != 0:
			if hand.get_child(0).type == "pistol":
				hand.get_child(0).reparent(leg,false)
			elif hand.get_child(0).type == "prim":
				hand.get_child(0).reparent(shoulder_l, false)
			else:
				hand.get_child(0).reparent(shoulder_r, false)
		if !melee:
			a.get_child(0).reparent(hand, false)

func shoot(gun) -> void:
	if !inventory.visible:
		if gun.current_ammo != 0 and !hand.get_child(0).gun_anim.is_playing():
			gun.fire()
			gun.fire_sfx.play(0.15)
			if fire_ray.is_colliding():
				var bullet_inst = bullet.instantiate()
				gun.fire_pos.add_child(bullet_inst)
				bullet_inst.look_at(fire_ray.get_collision_point(), Vector3.UP)
			gun.current_ammo -= 1

func reload(gun) -> void:
	if gun.current_ammo == 0 and gun.ammo != 0:
		if !hand.get_child(0).gun_anim.is_playing():
			hand.get_child(0).reload_gun(true)

func drop_item_from_inventory(item: Node3D) -> void:
	if item:
		item.reparent(get_parent())
		item.global_position = drop_pos.global_position

func toggle_light() -> void:
	print("turned_on_light")

func toggle_inventory() -> void:
	if Input.is_action_just_pressed("inventory"):
		inventory.visible = !inventory.visible
		if has_ammunition:
			$ui/ammo_slot.visible = inventory.visible
		if inventory.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func  health_and_strength() -> void:
	health_bar.value = health
	strength_bar.value = strength

func showmessege(text:String) -> void:
	$ui/messegebox.get_child(0).text = str(text)
	$ui/messegebox.get_child(1).play_section("in", 0.0)

func _on_health_bar_value_changed(_value: float) -> void:
	health_bar.show()
	var tm = get_tree().create_timer(4).timeout
	await tm
	health_bar.hide()

func _on_strength_bar_value_changed(_value: float) -> void:
	strength_bar.show()
	var tm = get_tree().create_timer(4).timeout
	await tm
	strength_bar.hide()
