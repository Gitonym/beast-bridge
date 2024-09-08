extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	wfc = WaveFunctionCollapseGrid.new(2, 2, 2, 4, CellItemDefinitions.definitions)
	add_child(wfc)
	wfc.collapse_all()
	wfc.spawn_items()
	print("test")
