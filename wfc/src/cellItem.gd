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
var rotation: Vector3


func _init(_item_name: StringName, _model_path: String, _valid_neighbours: Dictionary,  _rotation = Vector3.RIGHT):
	item_name = _item_name
	model_path = _model_path
	valid_neighbours = _valid_neighbours
	rotation = _rotation


func track() -> CellItem:
	CellItem.definitions.append(self)
	return self

func generate_rotations() -> void:
	CellItem.new(
		self.item_name,
		self.model_path,
		{
			Vector3.RIGHT:   self.valid_neighbours[Vector3.BACK],
			Vector3.LEFT:    self.valid_neighbours[Vector3.FORWARD],
			Vector3.UP:      self.valid_neighbours[Vector3.UP],
			Vector3.DOWN:    self.valid_neighbours[Vector3.DOWN],
			Vector3.BACK:    self.valid_neighbours[Vector3.LEFT],
			Vector3.FORWARD: self.valid_neighbours[Vector3.RIGHT]
		},
		Vector3.FORWARD
	).track()
