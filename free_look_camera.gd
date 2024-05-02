#Copyright © 2022 Marc Nahr: https://github.com/MarcPhi/godot-free-look-camera
extends Camera3D

@export_range(0, 10, 0.01) var sensitivity: float = 3
@export_range(0, 1000, 0.1) var default_velocity: float = 5
@export_range(0, 10, 0.01) var speed_scale: float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier: float = 3.0
@export var max_speed: float = 1000
@export var min_speed: float = 0.2

@onready var _velocity = default_velocity

# Variables for following a random boid
@export var following = false

@export_category("Miscellaneous Settings")
var camera_marker: Node3D

# General Creature Variables
@export_category("General Settings")
@export var camera: Camera3D
@onready var original_camera_switch_position: Vector3 = camera.global_position
@export var camera_to_creature_timer: Timer
@export var duration_to_start_control: float = 2.0

var follow_button_pressed = false
var time_button_pressed = false

var followTriggered = false
var unfollowTriggered = false

var random_boid

var time_stopped = false

func _ready():
	pass

func _input(event):
	if not current:
		return

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / 1000 * sensitivity
			rotation.x -= event.relative.y / 1000 * sensitivity
			rotation.x = clamp(rotation.x, PI / - 2, PI / 2)

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
				_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)

	#if Input.is_physical_key_pressed(KEY_Z) and following and camera_to_creature_timer.is_stopped() and !follow_button_pressed:
		#camera_to_creature_timer.start()
		#follow_button_pressed = true
		#following = false
		##print("Follow Released!")
	#elif Input.is_key_pressed(KEY_Z) and !following and camera_to_creature_timer.is_stopped() and !follow_button_pressed:
		#original_camera_switch_position = camera.global_position
		#camera_to_creature_timer.start()
		#follow_button_pressed = true
		#following = true
		##print("A Creature is now being followed!")
		
	#if Input.is_physical_key_pressed(KEY_X) and !time_button_pressed and !time_stopped:
		#time_button_pressed = true
		#time_stop()
	#elif Input.is_physical_key_pressed(KEY_X) and !time_button_pressed and time_stopped:
		#time_button_pressed = true
		#time_resume()

#func follow(lerp_timeline, lerp_timeline_rotation):
#
	## The goal is to call look_at constantly in a look towards the mother bird.
	#slow_rotate_to_target(random_boid.global_position, lerp_timeline_rotation)
#
	#camera.global_position = lerp(original_camera_switch_position, camera_marker.global_position, lerp_timeline)
#
#func unfollow(lerp_timeline):
	#camera.global_position = lerp(camera_marker.global_position, original_camera_switch_position, lerp_timeline)
#
#func slow_rotate_to_target(target, lerp_timeline):
	#var previous_value = Vector3.ZERO
	#var next_value = Vector3i.ONE
	#var forward = target - camera.global_transform.origin
	#forward = forward.normalized() * -1
#
	#var right = Vector3.UP.cross(forward).normalized()
	#var up = forward.cross(right).normalized()
#
	#var new_basis = Basis(right, up, forward)
	#var new_rotation = new_basis.get_euler()
	#var current_rotation = camera.global_transform.basis.get_euler()
	#var final_rotation = current_rotation.cubic_interpolate(new_rotation, previous_value, next_value, lerp_timeline)
	#camera.global_rotation = final_rotation
#
#func time_stop():
	#Engine.time_scale = 0.15
	#time_stopped = true
	#time_button_pressed = false
	#
#func time_resume():
	#Engine.time_scale = 1
	#time_stopped = false
	#time_button_pressed = false

func _process(delta):

	#var duration = float(duration_to_start_control - camera_to_creature_timer.time_left)
	#var lerp_timeline = Tween.interpolate_value(0.0, 1.0, duration, duration_to_start_control, Tween.TRANS_EXPO, Tween.EASE_OUT)
	#var lerp_timeline_rotation = Tween.interpolate_value(0.0, 1.0, duration, duration_to_start_control, Tween.TRANS_LINEAR, Tween.EASE_OUT)
#
	##print("Lerp timeline is: (" + str(lerp_timeline) + ")")
#
	#if following and !camera_to_creature_timer.is_stopped() and follow_button_pressed:
		#follow_button_pressed = false
#
		#var num_of_boids = $"../../../../Manager".get_num_of_units()
		#var random_boid_chooser = randi() % num_of_boids
		#random_boid = get_tree().get_nodes_in_group("boid")[random_boid_chooser]
		#var look_at_steps_control = 100
#
		#for node in random_boid.get_children():
			#if node.is_in_group("marker"):
				##print("camera marker found!")
				#camera_marker = node
#
		## if self.is_in_group("mother"):
		## 	camera.look_at(self.global_position, Vector3.UP)
		#followTriggered = true
		#follow(lerp_timeline, lerp_timeline_rotation)
	#elif !following and !camera_to_creature_timer.is_stopped() and follow_button_pressed:
		#follow_button_pressed = false
		#unfollowTriggered = true
		#unfollow(lerp_timeline)

	if not current:
		return

	var direction = Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()

	if Input.is_physical_key_pressed(KEY_SHIFT): # boost
		translate(direction * _velocity * delta * boost_speed_multiplier)
	else:
		translate(direction * _velocity * delta)

	#if lerp_timeline < 1.0 && followTriggered:
		#follow(lerp_timeline, lerp_timeline_rotation)
	#else:
		#followTriggered = false
#
	#if lerp_timeline < 1.0 && unfollowTriggered:
		#unfollow(lerp_timeline)
	#else:
		#unfollowTriggered = false
