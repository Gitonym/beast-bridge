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

# create two cellItems rotated by 90 degrees
static func newMirrored(p_item_name: String, p_scene_path: String, key_right: String, key_forward: String, key_left: String, key_back: String, key_up: String, key_down: String) -> Array[CellItem]:
	var x = CellItem.new(p_item_name + "_x", p_scene_path, key_right, key_forward, key_left, key_back, key_up, key_down, Vector3.RIGHT)
	var z = x.create_rotation()
	return [x, z]


# creates 4 cellItems each with a different direction
static func newCardinal(p_item_name: String, p_scene_path: String, key_right: String, key_forward: String, key_left: String, key_back: String, key_up: String, key_down: String) -> Array[CellItem]:
	var r = CellItem.new(p_item_name + "_r", p_scene_path, key_right, key_forward, key_left, key_back, key_up, key_down, Vector3.RIGHT)
	var f = r.create_rotation()
	var l = f.create_rotation()
	var b = l.create_rotation()
	return [r, f, l, b]


func create_rotation() -> CellItem:
	var rotate = {
		Vector3.RIGHT: Vector3.FORWARD,
		Vector3.FORWARD: Vector3.LEFT,
		Vector3.LEFT: Vector3.BACK,
		Vector3.BACK: Vector3.RIGHT,
	}
	return CellItem.new(rotate_key(item_name), scene_path, rotate_key(keys[Vector3.BACK]), rotate_key(keys[Vector3.RIGHT]), rotate_key(keys[Vector3.FORWARD]), rotate_key(keys[Vector3.LEFT]), rotate_key(keys[Vector3.UP]), rotate_key(keys[Vector3.DOWN]), rotate[rotation])

# checks if the given string has a rotational suffix such as "_r" and changes it to "_f"
static func rotate_key(key: String) -> String:
	var rotate = {
		"_x": "_z",
		"_z": "_x",
		"_r": "_f",
		"_f": "_l",
		"_l": "_b",
		"_b": "_r"
	}
	for dir in rotate:
		if key.ends_with(dir):
			return key.reverse().substr(2).reverse() + rotate[dir]
	return key
