class_name Creature extends CharacterBody3D

@export_category("Creature Settings")
@export var speed = 5
@export var jump_height = 5
@export var controlling = false

@export_category("Miscellaneous Settings")
@export var camera_marker: Marker3D

# General Creature Variables
@export_category("General Settings")
@onready var camera: Camera3D = $"../Camera3D"
@onready var original_camera_switch_position: Vector3 = camera.global_position
@export var camera_to_creature_timer: Timer 
@export var duration_to_start_control: float = 2.0

var control_button_pressed = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_to_creature_timer.stop()
	camera_to_creature_timer.wait_time = duration_to_start_control
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	
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
		
		camera_marker.look_at(self.global_position, Vector3.UP)
		
		# Follow the player
		camera.global_position = lerp(camera.global_position, camera_marker.global_position, 1)
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

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
	else:
		pass
		

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
	camera.global_position = lerp(original_camera_switch_position, camera_marker.global_position, lerp_timeline)
	camera.global_rotation = lerp(camera.global_rotation, camera_marker.global_rotation, lerp_timeline_rotation)


func uncontrol(lerp_timeline):
	camera.global_position = lerp(camera_marker.global_position, original_camera_switch_position, lerp_timeline)
