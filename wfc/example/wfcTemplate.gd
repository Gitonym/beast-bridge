# This script shows a usage example of the WaveFunctionCollapse template creation system
extends Node3D


var wfcT: WaveFunctionCollapseTemplate

func _ready():
	var cell_items: Array[CellItem] = [
		CellItem.new(&"air", "", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []}),
		CellItem.new(&"ground", "res://wfc/items/models/cube.glb", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []}),
		CellItem.new(&"tree", "res://wfc/items/models/tree.glb", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []}),
		CellItem.new(&"gate", "res://wfc/items/models/gate.glb", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []}),
		CellItem.new(&"water", "res://wfc/items/models/water.glb", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []}),
		CellItem.new(&"ramp", "res://wfc/items/models/ramp.glb", {Vector3.RIGHT: [], Vector3.LEFT: [], Vector3.UP: [], Vector3.DOWN: [], Vector3.BACK: [], Vector3.FORWARD: []})
	]
	wfcT = WaveFunctionCollapseTemplate.new(Vector3(10, 5, 10), 4, cell_items)
	add_child(wfcT)
	wfcT.start()

func _process(_delta):
	pass
