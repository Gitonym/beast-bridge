extends CharacterBody3D

@export var movement_speed = 20
@export var running_speed = 50
@export var movement_acceleration = 10
@export var movement_friction = 4
@export var gravity_strength = 20
@export var jump_strength = 15

@onready var mage = $Mage
@onready var animationPlayer = $Mage/AnimationPlayer
@onready var interactRay = $Mage/InteractRay

var click_event: bool = false
var alt_click_event: bool = false
var state = "idle"
var movement_direction : Vector3 = Vector3(0, 0, 0)


func _process(_delta):
	#movement
	get_movement_direction()
	interpolate_player_rotation()
	land_on_ground()
	play_animations()
	#TODO: Reenable these features at some point
	#on_click_event()
	#on_alt_click_event()


func _physics_process(delta):
	accelerate(delta)
	friction(delta)
	#jump()
	#gravity(delta)
	interact()
	move_and_slide()


func _unhandled_input(event):
	click_event = event.is_action_pressed("click")
	alt_click_event = event.is_action_pressed("alt_click")


func get_movement_direction():
	#movement direction
	movement_direction = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		movement_direction += Vector3(0, 0, -1)
	if Input.is_action_pressed("move_down"):
		movement_direction += Vector3(0, 0, 1)
	if Input.is_action_pressed("move_left"):
		movement_direction += Vector3(-1, 0, 0)
	if Input.is_action_pressed("move_right"):
		movement_direction += Vector3(1, 0, 0)
	if Input.is_action_pressed("jump"):
		movement_direction += Vector3(0, 1, 0)
	if Input.is_action_pressed("crouch"):
		movement_direction += Vector3(0, -1, 0)
	movement_direction = movement_direction.normalized()


func interpolate_player_rotation():
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	if horizontal_velocity.length() > 0:
		#interpolate rotation
		var current_rotation = mage.rotation
		var current_quat = Quaternion(mage.transform.basis)
		if not is_equal_approx(velocity.length(), 0.0) and (global_position - velocity) != Vector3.FORWARD and (global_position - velocity) != Vector3.BACK:
			mage.look_at(global_position - velocity, Vector3.UP)
		mage.rotation.x = current_rotation.x
		var target_quat = Quaternion(mage.transform.basis)
		mage.rotation = current_rotation
		var intermediate_quat = current_quat.slerp(target_quat, 0.5)
		#look in movement direction
		mage.transform.basis = Basis(intermediate_quat)


func accelerate(delta):
	var current_speed = movement_speed
	if Input.is_action_pressed("sprint"):
		current_speed = running_speed
	velocity += movement_direction * current_speed * movement_acceleration * delta
	
	#clamp max speed
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	if horizontal_velocity.length() > current_speed:
		horizontal_velocity = horizontal_velocity.normalized() * current_speed
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y


func friction(delta):
	#fiction
	velocity -= velocity * movement_friction * delta


func play_animations():
	if state == "idle":
		if is_on_floor():
			if velocity.length() > 5:
				animationPlayer.play("Running_A", -1, 2)
			elif velocity.length() > 1:
				animationPlayer.play("Running_B", -1, 2)
			else:
				animationPlayer.play("Idle", 0.1, 1)
		else:
			animationPlayer.play("Jump_Idle", 0.5, 1)
	
	if state == "jump_land" or state == "interact":
		if velocity.length() > 0.5:
			animationPlayer.play("Running_B", -1, 2)
			state = "idle"
	
	if state == "interact":
		animationPlayer.play("Interact")


func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		animationPlayer.play("Jump_Start")
		state = "jump_start"


func gravity(delta):
	velocity.y -= gravity_strength * delta


func _on_jumping_in_animation():
	velocity.y = jump_strength


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Jump_Start":
		animationPlayer.play("Jump_Idle")
		state = "jump_mid"
	if anim_name == "Interact":
		state = "idle"


func land_on_ground():
	if state == "jump_mid" and is_on_floor():
		animationPlayer.play("Jump_Land")
		state = "jump_land"


func interact():
	if Input.is_action_just_pressed("interact"):
		var body = interactRay.get_collider()
		if body == null:
			return
		if body.has_method("interact"):
			body.interact()
			animationPlayer.play("Interact")
			state = "interact"
