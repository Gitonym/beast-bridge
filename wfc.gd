extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	wfc = WaveFunctionCollapseGrid.new(25, 5, 25, 4, CellItem.definitions)
	add_child(wfc)
	wfc.collapse_all()
	wfc.spawn_items()
