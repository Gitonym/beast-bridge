class_name CellItem
extends Node


var item_name: StringName
var model_path: String
var rotatable: bool

var valid_neighbours_positive_x: Array[StringName]
var valid_neighbours_negative_x: Array[StringName]
var valid_neighbours_positive_y: Array[StringName]
var valid_neighbours_negative_y: Array[StringName]
var valid_neighbours_positive_z: Array[StringName]
var valid_neighbours_negative_z: Array[StringName]

#construcotr for all sides
func _init(
	_item_name: StringName,
	_model_path: String,
	_rotatable: bool,
	_valid_neighbours_positive_x: Array[StringName],
	_valid_neighbours_negative_x: Array[StringName],
	_valid_neighbours_positive_y: Array[StringName],
	_valid_neighbours_negative_y: Array[StringName],
	_valid_neighbours_positive_z: Array[StringName],
	_valid_neighbours_negative_z: Array[StringName]
	):
	item_name = _item_name
	model_path = _model_path
	rotatable = _rotatable
	valid_neighbours_positive_x = _valid_neighbours_positive_x
	valid_neighbours_negative_x = _valid_neighbours_negative_x
	valid_neighbours_positive_y = _valid_neighbours_positive_y
	valid_neighbours_negative_y = _valid_neighbours_negative_y
	valid_neighbours_positive_z = _valid_neighbours_positive_z
	valid_neighbours_negative_z = _valid_neighbours_negative_z


func get_valid_neighbours_for_direction(direction: Vector3) -> Array[StringName]:
	if direction == Vector3(1, 0, 0):
		return valid_neighbours_positive_x
	elif direction == Vector3(-1, 0, 0):
		return valid_neighbours_negative_x
	elif direction == Vector3(0, 1, 0):
		return valid_neighbours_positive_y
	elif direction == Vector3(0, -1, 0):
		return valid_neighbours_negative_y
	elif direction == Vector3(0, 0, 1):
		return valid_neighbours_positive_z
	elif direction == Vector3(0, 0, -1):
		return valid_neighbours_negative_z
	else:
		return [&"ERROR"]
