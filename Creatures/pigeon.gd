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
@export var rayCast: RayCast3D
@export var debug_mesh: MeshInstance3D

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
enum Axis {Horizontal, Vertical}

var control_button_pressed = false
var target: Vector3
var world_target: Vector3
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
		# if self.is_in_group("mother"):
		# 	camera.look_at(self.global_position, Vector3.UP)
		control(lerp_timeline, lerp_timeline_rotation)
	elif !controlling and !camera_to_creature_timer.is_stopped() and control_button_pressed:
		set_velocity(Vector3.ZERO)
		uncontrol(lerp_timeline)

	if controlling and camera_to_creature_timer.is_stopped():

		if self.is_in_group("mother"):
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
		translate(Vector3( - forward_dir, 0, 0) * speed * delta)

		move_and_slide()
	elif !controlling and camera_to_creature_timer.is_stopped():
		# Add the gravity.
		if not is_on_floor():
			creature_animator.play("WingFlap")
			velocity.y -= gravity * delta
		else:
			creature_animator.play("RESET")

		var noise_force = noise_wander(rayCast)
		#force = lerp(force, new_force, delta)

		#acceleration = new_force / mass
		#vel += acceleration # * delta
		boid_stuff(delta, noise_force)

# Input to posess a creature
func _input(event):
	if Input.is_physical_key_pressed(KEY_Z) and !event.echo and controlling and camera_to_creature_timer.is_stopped() and !control_button_pressed:
		camera_to_creature_timer.start()
		control_button_pressed = true
		controlling = false
		print("CONTROL RELEASED!")
	elif Input.is_key_pressed(KEY_Z) and !event.echo and !controlling and camera_to_creature_timer.is_stopped() and !control_button_pressed:
		original_camera_switch_position = camera.global_position
		camera_to_creature_timer.start()
		control_button_pressed = true
		controlling = true
		print("A Creature is now being controlled!")

	if Input.is_physical_key_pressed(KEY_X) and !event.echo:
		camera.look_at(self.global_position, Vector3.UP)

func jump(jump_height):
	velocity.y = jump_height

func control(lerp_timeline, lerp_timeline_rotation):
	var mother_boid = self
	var look_at_steps_control = 100

	# The goal is to call look_at constantly in a look towards the mother bird.
	for i in range(look_at_steps_control):
		var look_at_direction = mother_boid.global_position - camera.global_position
		# var rotation_to_creature = look_at_direction.angle_to(Vector3.FORWARD)
		camera.look_at(mother_boid.global_position, Vector3.UP)

	camera.global_position = lerp(original_camera_switch_position, camera_marker.global_position, lerp_timeline)
	# camera.global_rotation = lerp(camera.global_rotation, rotation_to_creature, lerp_timeline_rotation)
	# camera.global_transform.basis = lerp(camera.global_transform.basis, Basis(look_at_direction, Vector3.UP, -look_at_direction.cross(Vector3.UP)), lerp_timeline_rotation)

func uncontrol(lerp_timeline):
	camera.global_position = lerp(camera_marker.global_position, original_camera_switch_position, lerp_timeline)

func noise_wander(rayCast):
	var delta = get_process_delta_time()

	var forward_direction = Vector3.FORWARD
	var steering_direction = Vector3.ZERO
	var fake_target_position = Vector3(rayCast.global_position.x - 10, rayCast.global_position.y, rayCast.global_position.z)

	var steering_position = rayCast.target_position + steering_direction * distance

	theta += frequency * delta * PI * 2.0

	if axis == Axis.Horizontal:
		steering_direction.x = sin(theta)
		steering_direction.z = cos(theta)
	else:
		steering_direction.y = sin(theta)
		steering_direction.z = cos(theta)

	debug_mesh.global_position = fake_target_position

	forward_direction = forward_direction.bezier_interpolate(fake_target_position, global_position, rayCast.target_position, 1.0)

	world_target = boid.global_transform.origin + (forward_direction)
	#boid.global_transform.origin = boid.global_transform.origin + (forward_direction * distance)

	return fake_target_position

func seek_force(target: Vector3):
	var toTarget = target - global_transform.origin
	toTarget = toTarget.normalized()
	var desired = toTarget * speed
	return desired - vel

func boid_stuff(delta, noise_force):
	#force = lerp(force, new_force, delta)

	if speed > 0:
		#vel = vel.limit_length(max_speed)

		# Damping
		#vel -= vel * delta * damping

		set_velocity(vel)
		# print("velocity at end is: " + str(vel))
		move_and_slide()

		# Implement Banking as described:
		# https://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/
		#var temp_up = global_transform.basis.y.lerp(Vector3.UP + (acceleration * banking), delta * 5.0)
		#look_at(global_transform.origin - vel.normalized(), temp_up)

func generic_Boids():
	for boi in get_tree().get_nodes_in_group("boid"):
		var N = 0
		if boi.is_flocking:
			# Separate: get average position of nearby boids
			var sep = Vector3()
			# Align: get average velocity direction of nearby boids
			var align = Vector3()
			# Cohesion: get average position of boids
			var coh = Vector3()

			for boi2 in get_tree().get_nodes_in_group("boid"):
				if boi2 != boi:
					continue
				var dist = (boi2.translation - boi.translation).length()
				if dist < radius:
					N += 1
					dist = clamp(0.1, radius, dist)
					sep += (boi2.translation - boi.translation).normalized() / dist
					align += boi2.velocity.normalized()
					coh += boi2.translation

			if N != 0:
				# move opposite the separation direction
				boi1.acc -= sep.normalized() * sep_weight

				# move towards alignment
				boi1.acc += align.normalized() * align_weight

				# move towards cohesion
				var target = coh / N
				boi1.acc += (target - boi1.translation) * coh_weight

			# Move towards interest location
			var d = (boi1.translation - interest).length()
			if d.length() > interest_radius:
				boi1.acc -= d.normalized() * interest_weight

func set_interest(interest):
	interest = interest

func is_flocking():
	return true
