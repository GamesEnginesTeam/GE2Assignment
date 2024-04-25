class_name Creature extends CharacterBody3D

@export_category("Creature Settings")
@export var speed = 5
@export var jump_height = 5
@export var controlling = false
@export var creature_animator: AnimationPlayer

@export_category("Miscellaneous Settings")
@export var camera_marker: Node3D

# General Creature Variables
@export_category("General Settings")
@export var camera: Camera3D
@onready var original_camera_switch_position: Vector3 = camera.global_position
@export var camera_to_creature_timer: Timer 
@export var duration_to_start_control: float = 2.0

@export_category("Noise Settings")
@export var noise: FastNoiseLite
@export var frequency = 0.3
@export var radius = 10.0
@export var axis = Axis.Horizontal
@export var theta = 0
@export var amplitude = 80
@export var distance = 5
@export var boid = self
@export var vel = Vector3.ZERO
@export var force = Vector3.ZERO
@export var acceleration = Vector3.ZERO
@export var mass = 1

# Enumerators
enum Axis { Horizontal, Vertical}

var control_button_pressed = false
var target:Vector3
var world_target:Vector3
var new_force = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_to_creature_timer.stop()
	camera_to_creature_timer.wait_time = duration_to_start_control
	
	noise.seed = randi()
	noise.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	noise.set_frequency(0.01)
	noise.set_fractal_lacunarity(2)
	noise.set_fractal_gain(0.5)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	
	if self.is_in_group("main_boid"):
			camera.look_at(self.global_position, Vector3.UP)
	
	## Add the gravity.
	#if not is_on_floor():
		#creature_animator.play("WingFlap")
		#velocity.y -= gravity * delta
	#else:
		#creature_animator.play("RESET")
	
	camera_marker.look_at(self.global_position)
	
	var duration = float(duration_to_start_control - camera_to_creature_timer.time_left) 
	var lerp_timeline = Tween.interpolate_value(0.0, 1.0, duration, duration_to_start_control, Tween.TRANS_EXPO, Tween.EASE_OUT)
	var lerp_timeline_rotation = Tween.interpolate_value(0.0, 1.0, duration, duration_to_start_control, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	if camera_to_creature_timer.is_stopped():
		control_button_pressed = false
	
	if controlling and !camera_to_creature_timer.is_stopped() and control_button_pressed:
		control(lerp_timeline, lerp_timeline_rotation)
	elif !controlling and !camera_to_creature_timer.is_stopped() and control_button_pressed:
		uncontrol(lerp_timeline)
	
	if controlling and camera_to_creature_timer.is_stopped():
		
		if self.is_in_group("main_boid"):
			camera.look_at(self.global_position, Vector3.UP)
		
		# Follow the player
		camera.global_position = lerp(camera.global_position, camera_marker.global_position, 1)
		
		# Add the gravity.
		if not is_on_floor():
			creature_animator.play("WingFlap")
			velocity.y -= gravity * delta
		else:
			creature_animator.play("RESET")

		# Handle jump.
		if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
			jump(jump_height)
			
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var turn_dir = Input.get_axis("ui_right", "ui_left")
		var forward_dir = Input.get_axis("ui_down", "ui_up")

		# rotate the player
		rotate_object_local(Vector3.UP, turn_dir * delta)
		translate(Vector3(-forward_dir, 0, 0) * speed * delta)

		move_and_slide()
	elif !controlling and camera_to_creature_timer.is_stopped():
		# Add the gravity.
		if not is_on_floor():
			creature_animator.play("WingFlap")
			velocity.y -= gravity * delta
		else:
			creature_animator.play("RESET")
			
		var noise_force = noise_wander()
		#force = lerp(force, new_force, delta)
		
		#acceleration = new_force / mass
		#vel += acceleration # * delta
		boid_stuff(delta, noise_force)
		

# Input to posess a creature
func _input(event):
	if Input.is_physical_key_pressed(KEY_Z) and event.pressed and !event.echo and controlling and camera_to_creature_timer.is_stopped() and !control_button_pressed:
		camera_to_creature_timer.start()
		control_button_pressed = true
		controlling = false
		print("CONTROL RELEASED!")
	elif Input.is_key_pressed(KEY_Z) and event.pressed and !event.echo and !controlling and camera_to_creature_timer.is_stopped() and !control_button_pressed:
		original_camera_switch_position = camera.global_position
		camera_to_creature_timer.start()
		control_button_pressed = true
		controlling = true
		print("A Creature is now being controlled!")

func jump(jump_height):
	velocity.y = jump_height


func control(lerp_timeline, lerp_timeline_rotation):
	#var rotation_to_creature = camera_marker.global_rotation - camera.global_rotation
	
	camera.global_position = lerp(original_camera_switch_position, camera_marker.global_position, lerp_timeline)
	#camera.global_rotation = lerp(camera.global_rotation, rotation_to_creature, lerp_timeline_rotation)


func uncontrol(lerp_timeline):
	camera.global_position = lerp(camera_marker.global_position, original_camera_switch_position, lerp_timeline)


func noise_wander():
	var n  = noise.get_noise_1d(theta)
	var angle = deg_to_rad(n * amplitude)
	
	var delta = get_process_delta_time()

	var rot = boid.global_transform.basis.get_euler()
	rot.x = 0
	

	if axis == Axis.Horizontal:
		target.x = sin(angle)
		target.z =  cos(angle)
		target.y = 0
		rot.z = 0
	else:
		target.y = sin(angle)
		target.z = cos(angle)
		target.x = 0
		
	target *= radius

	var local_target = target + (Vector3.BACK * distance)
	
	var projected = Basis.from_euler(rot)
	
	world_target = boid.global_transform.origin + (projected * local_target)	
	theta += frequency * delta * PI * 2.0

	return seek_force(world_target)

func seek_force(target: Vector3):	
	var toTarget = target - global_transform.origin
	toTarget = toTarget.normalized()
	var desired = toTarget * speed
	return desired - vel


func boid_stuff(delta, noise_force):
	#force = lerp(force, new_force, delta)
		
	acceleration = noise_force / mass
	vel += acceleration #* delta
	speed = vel.length()
	if speed > 0:		
		#vel = vel.limit_length(max_speed)
		
		# Damping
		#vel -= vel * delta * damping
		
		set_velocity(vel)
		print("velocity at end is: " + str(vel))
		move_and_slide()
		
		# Implement Banking as described:
		# https://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/
		#var temp_up = global_transform.basis.y.lerp(Vector3.UP + (acceleration * banking), delta * 5.0)
		#look_at(global_transform.origin - vel.normalized(), temp_up)
