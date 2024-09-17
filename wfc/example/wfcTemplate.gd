# This script shows a usage example of the WaveFunctionCollapse template creation system
extends Node3D


# this class manages a scene that
var wfcT: WaveFunctionCollapseTemplate

func _ready():
	var cell_items: Array[CellItem] = [
		#CellItem.new(&"air", "", false),
		#CellItem.new(&"ground", "res://wfc/items/models/cube.glb", false),
		#CellItem.new(&"tree", "res://wfc/items/models/tree.glb", false),
		#CellItem.new(&"gate", "res://wfc/items/models/gate.glb", true),
		#CellItem.new(&"water", "res://wfc/items/models/water.glb", false),
		#CellItem.new(&"ramp", "res://wfc/items/models/ramp.glb", true)
	]
	
	wfcT = WaveFunctionCollapseTemplate.new(Vector3(15, 10, 15), 4, cell_items)
	add_child(wfcT)
	wfcT.restore_template_from_file()
