# this class represents one possible item that can be in the grid
# an item represents the mesh that will be rendered and its rotation
class_name CellItem
extends Node


var item_name: StringName					# name of this item, should be unique except for its rotations
var scene_path: String						# the path to the scene that should be created when the grid is done
var rotation: Vector3						# stores the rotation if this item

# the key that determines valid and invalid neighbours
# two cellItems can only be adjecent if their keys match in the others direction
var keys: Dictionary


# cosntructor
func _init(p_item_name: StringName, p_scene_path: String, key_right: StringName, key_forward: StringName, key_left: StringName, key_back: StringName, key_up: StringName, key_down: StringName, p_rotation = Vector3.RIGHT):
	item_name = p_item_name
	scene_path = p_scene_path
	rotation = p_rotation
	keys = {
		Vector3.RIGHT: key_right,
		Vector3.FORWARD: key_forward,
		Vector3.LEFT: key_left,
		Vector3.BACK: key_back,
		Vector3.UP: key_up,
		Vector3.DOWN: key_down,
	}


func clone() -> CellItem:
	return CellItem.new(item_name, scene_path, keys[Vector3.RIGHT], keys[Vector3.FORWARD], keys[Vector3.LEFT], keys[Vector3.BACK], keys[Vector3.UP], keys[Vector3.DOWN], rotation)
