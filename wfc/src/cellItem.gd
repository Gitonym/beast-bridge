# this class represents one possible item that can be in the grid
# an item represents the mesh that will be rendered and its rotation
class_name CellItem
extends Node


var item_name: StringName					# name of this item, should be unique except for its rotations
var model_path: String						# the path to the scene that should be created when the grid is done
var rotation: Vector3						# stores the rotation if this item


func _init(_item_name: StringName, _model_path: String,  _rotation = Vector3.RIGHT):
	item_name = _item_name
	model_path = _model_path
	rotation = _rotation


func clone() -> CellItem:
	return CellItem.new(item_name, model_path, rotation)


func equals(other: CellItem) -> bool:
	if self == other:
		return true
	if item_name == other.item_name and rotation == other.rotation:
		return true
	return false
