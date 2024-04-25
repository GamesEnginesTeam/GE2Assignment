extends CharacterBody3D


const JUMP_VELOCITY = 4.5
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var Aligment_weight := 0.4
@export var Cohension_weight := 0.2
@export var Separartion_weight := 0.2
@export var Neighbor_Radious := 5.0

@export var Max_speed = 3.0
@export var Min_speed = 1.0

@export var Max_Acceleration := 0.2
@export var Rotation_speed := 2.0

var alignment = Vector3.ZERO
var cohension = Vector3.ZERO
var separation = Vector3.ZERO
var count = 0

var unit_arry = []

func _onready():
	randomize()
	pass


func _physics_process(delta: float) -> void:
		
	alignment = Vector3.ZERO
	cohension = Vector3.ZERO
	separation  = Vector3.ZERO
	count = 0
	
	for unit in unit_arry:
		var dist = global_position.distance_to(unit.global_position)
		if unit != self and dist < Neighbor_Radious:
			alignment += unit.velocity
			cohension += unit.global_position
			separation += (global_position - unit.global_position) /dist
			count += 1
			
	if count > 0 :
		calc_alignment()
		calc_cohesion()
		calc_separartion()
		
	velocity += alignment * Aligment_weight + cohension * Cohension_weight + separation * Separartion_weight
	
	if velocity.length() > Max_speed:
		velocity = velocity.normalized() * randf_range(Min_speed, Max_speed)
	elif velocity.length() == 0:
		velocity = Vector3(randf(), 0, randf())
		velocity = velocity.normalized() * Max_speed
		
	var direction = velocity.normalized()
	var current_rotation = get_rotation()
	if direction != Vector3.ZERO:
		var target_basis = Basis.looking_at(-direction, Vector3.UP)
		var current_basis = transform.basis
		var t = Rotation_speed * delta
		var new_basis = current_basis.orthonormalized().slerp(target_basis, t)
		transform.basis = new_basis
		
	global_position += velocity * delta


	move_and_slide()

func calc_alignment():
	alignment = alignment / count
	alignment = alignment.normalized() * Max_speed - velocity
	if alignment.length() > Max_Acceleration:
		alignment = alignment.normalized() * Max_Acceleration
		
func calc_cohesion():
	cohension = (cohension / count) - global_position
	cohension = cohension.normalized() * Max_speed - velocity
	if cohension.length() > Max_Acceleration:
		cohension = cohension.normalized() * Max_Acceleration
	pass
	
func calc_separartion():
	separation = separation / count
	if separation.length() > 0:
		separation = separation.normalized() * Max_speed - velocity
		if separation.length() > Max_Acceleration:
			separation = separation.normalized() * Max_Acceleration
	pass
