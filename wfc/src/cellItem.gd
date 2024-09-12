# this class represents one possible item that can be in the grid
# an item represents the mesh that will be rendered and its rotation
class_name CellItem
extends Node


var item_name: StringName					# name of this item, should be unique except for its rotations
var model_path: String						# the path to the scene that should be created when the grid is done
var valid_neighbours: Dictionary = {		# stores the rules of which neighbours are valid
	Vector3.RIGHT:   [],
	Vector3.LEFT:    [],
	Vector3.UP:      [],
	Vector3.DOWN:    [],
	Vector3.BACK:    [],
	Vector3.FORWARD: []
}
var rotation: Vector3						# stores the rotation if this item


func _init(_item_name: StringName, _model_path: String, _valid_neighbours: Dictionary,  _rotation = Vector3.RIGHT):
	item_name = _item_name
	model_path = _model_path
	valid_neighbours = _valid_neighbours
	rotation = _rotation


# returns self and CellItems of the other three possible rotations
# TODO: adjust weights when generating rotations. Multiply by 0.25
# TODO: symmetric CellItems dont need all rotations
func generate_rotations() -> Array[CellItem]:
	var rotations: Array[CellItem] = [self]
	
	rotations.append(
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
		)
	)
	
	rotations.append(
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
		)
	)
	
	rotations.append(
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
		)
	)
	
	return rotations


func clone() -> CellItem:
	return CellItem.new(
		item_name,
		model_path,
		{
			Vector3.RIGHT:   [],
			Vector3.LEFT:    [],
			Vector3.UP:      [],
			Vector3.DOWN:    [],
			Vector3.BACK:    [],
			Vector3.FORWARD: []
		}
	)
