class_name CellItem
extends Node


static var definitions: Array[CellItem] = []

var item_name: StringName
var model_path: String

var valid_neighbours: Dictionary = {
	Vector3.RIGHT:   [],
	Vector3.LEFT:    [],
	Vector3.UP:      [],
	Vector3.DOWN:    [],
	Vector3.BACK:    [],
	Vector3.FORWARD: []
}


func _init(_item_name: StringName, _model_path: String, _valid_neighbours: Dictionary):
	item_name = _item_name
	model_path = _model_path
	valid_neighbours = _valid_neighbours


func track() -> CellItem:
	CellItem.definitions.append(self)
	return self
