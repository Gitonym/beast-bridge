# This script shows a usage example of the WaveFunctionCollapse template creation system
extends Node3D


var wfcT: WaveFunctionCollapseTemplate

func _ready():
	var cell_items: Array[CellItem] = [
		CellItem.new(&"air", ""),
		CellItem.new(&"ground", "res://wfc/items/models/cube.glb"),
		CellItem.new(&"tree", "res://wfc/items/models/tree.glb"),
		CellItem.new(&"gate", "res://wfc/items/models/gate.glb"),
		CellItem.new(&"water", "res://wfc/items/models/water.glb"),
		CellItem.new(&"ramp", "res://wfc/items/models/ramp.glb")
	]
	wfcT = WaveFunctionCollapseTemplate.new(Vector3(10, 5, 10), 4, cell_items)
	add_child(wfcT)
	wfcT.start()

func _process(_delta):
	pass
