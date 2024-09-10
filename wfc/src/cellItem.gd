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


# Adds the CellItem to CellItem.definitions. This should happen for every CellItem but self does not
# seem to work in _init
func track() -> CellItem:
	CellItem.definitions.append(self)
	return self


# Adds the CellItems of the other three possible rotations to CellItem.definitions
# TODO: adjust weights when generating rotations. Multiply by 0.25
# TODO: symmetric CellItems dont need all rotations
func generate_rotations() -> void:
	# Forward
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
	# Left
	CellItem.new(
		self.item_name,
		self.model_path,
		{
			Vector3.RIGHT:   self.valid_neighbours[Vector3.LEFT],
			Vector3.LEFT:    self.valid_neighbours[Vector3.RIGHT],
			Vector3.UP:      self.valid_neighbours[Vector3.UP],
			Vector3.DOWN:    self.valid_neighbours[Vector3.DOWN],
			Vector3.BACK:    self.valid_neighbours[Vector3.FORWARD],
			Vector3.FORWARD: self.valid_neighbours[Vector3.BACK]
		},
		Vector3.LEFT
	).track()
	# Back
	CellItem.new(
		self.item_name,
		self.model_path,
		{
			Vector3.RIGHT:   self.valid_neighbours[Vector3.FORWARD],
			Vector3.LEFT:    self.valid_neighbours[Vector3.BACK],
			Vector3.UP:      self.valid_neighbours[Vector3.UP],
			Vector3.DOWN:    self.valid_neighbours[Vector3.DOWN],
			Vector3.BACK:    self.valid_neighbours[Vector3.RIGHT],
			Vector3.FORWARD: self.valid_neighbours[Vector3.LEFT]
		},
		Vector3.BACK
	).track()
