extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	wfc = WaveFunctionCollapseGrid.new(50, 5, 50, 4, CellItem.definitions)
	add_child(wfc)
	wfc.collapse_all()
	wfc.spawn_items()
