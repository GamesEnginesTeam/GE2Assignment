extends Node3D

class_name FishManager


@export var num_of_units : int =  20
@export var map_limits : Vector3 = Vector3(5, 5, 5)
@export var unit_scene : PackedScene

func spawn_unit(new_position):
	var unit = unit_scene.instantiate()
	unit.position = new_position
	add_child(unit)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	for i in range(num_of_units):
		spawn_unit(Vector3(
			randf_range(-map_limits.x, map_limits.x),
			randf_range(-map_limits.y, map_limits.y),
			randf_range(-map_limits.z, map_limits.z)
		))

	pass # Replace with function body.

