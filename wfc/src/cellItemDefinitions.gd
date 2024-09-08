extends Node
class_name CellItemDefinitions

static var definitions: Array[CellItem] = [
	CellItem.new(&"air", "", false, [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"], [&"air"], [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"]),
	CellItem.new(&"ground", "res://wfc/items/models/cube.glb", false, [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"], [&"ground"], [&"air", &"ground", &"tree", &"gate"], [&"air", &"ground", &"tree", &"gate"]),
	CellItem.new(&"tree", "res://wfc/items/models/tree.glb", false, [&"air", &"tree", &"ground", &"gate"], [&"air", &"tree", &"ground", &"gate"], [&"air"], [&"ground"], [&"air", &"tree", &"ground", &"gate"], [&"air", &"tree", &"ground", &"gate"]),
	CellItem.new(&"gate", "res://wfc/items/models/gate.glb", false, [&"ground"], [&"ground"], [&"air", &"ground"], [&"ground"], [&"air"], [&"air"]),
]
