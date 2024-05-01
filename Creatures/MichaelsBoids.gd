extends Node3D

@export var ALIGNMENT_WEIGHT = 0.4
@export var COHESION_WEIGHT = 0.2
@export var SEPARATION_WEIGHT = 0.2
@export var NEIGHBOR_RADIUS = 3.0
@export var DETECTION_RADIUS = 10.0

@export var MAX_SPEED = 3.0
@export var MIN_SPEED = 1.0

@export var MAX_ACCELERATION = 0.2
@export var ROTATION_SPEED = 2.0

var alignment = Vector3.ZERO
var cohesion = Vector3.ZERO
var separation = Vector3.ZERO
var count = 0

var unit_array = []
var velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Boids")
	randomize()

func _physics_process(delta: float) -> void:
	find_neighbors()  # Update the list of neighbors
	alignment = Vector3.ZERO
	cohesion = Vector3.ZERO
	separation = Vector3.ZERO
	count = 0
	
	for unit in unit_array:
		var dist = global_position.distance_to(unit.global_position)
		if unit != self and dist < NEIGHBOR_RADIUS:
			alignment += unit.velocity
			cohesion += unit.global_position
			separation += (global_position - unit.global_position) / dist
			count += 1
	
	if count > 0:
		calc_alignment()
		calc_cohesion()
		calc_separation()
	
	velocity += alignment * ALIGNMENT_WEIGHT + cohesion * COHESION_WEIGHT + separation * SEPARATION_WEIGHT
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * randf_range(MIN_SPEED, MAX_SPEED)
	elif  velocity.length() == 0:
		velocity = Vector3(randf(), randf(), randf())
		velocity = velocity.normalized() * MAX_SPEED
	
	var direction = velocity.normalized()
	var current_rotation = get_rotation()
	if direction != Vector3.ZERO:
		var target_basis = Basis.looking_at(-direction, Vector3.UP)
		var current_basis = transform.basis
		var t = ROTATION_SPEED * delta
		var new_basis = current_basis.orthonormalized().slerp(target_basis, t)
		transform.basis = new_basis
		
	global_position += velocity * delta
	
	
	pass

func calc_alignment():
	alignment = alignment / count
	alignment = alignment.normalized() * MAX_SPEED - velocity
	if alignment.length() > MAX_ACCELERATION:
		alignment = alignment.normalized() * MAX_ACCELERATION
	
	
func calc_cohesion():
	cohesion = (cohesion / count) - global_position
	cohesion = alignment.normalized() * MAX_SPEED - velocity
	if cohesion.length() > MAX_ACCELERATION:
		cohesion = cohesion.normalized() * MAX_ACCELERATION

	
func calc_separation():
	separation = separation / count
	if separation.length() > 0:
		separation = separation.normalized() * MAX_SPEED - velocity
		if separation.length() >  MAX_ACCELERATION:
			separation = separation.normalized() * MAX_ACCELERATION
			
func find_neighbors():
	unit_array.clear()  # Clear the previous list of neighbors
	var all_units = get_tree().get_nodes_in_group("Boids")  # Fetch all boid nodes
	for unit in all_units:
		if unit != self:  # Ensure the unit is not the current boid
			var dist = global_position.distance_to(unit.global_position)
			if dist < DETECTION_RADIUS:
				unit_array.append(unit)

func generate_fish():
	
