extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	CellItem.new(
		&"air",
		"",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate"]
		}
	).track()
	
	CellItem.new(
		&"ground",
		"res://wfc/items/models/cube.glb",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.UP:      [&"air", &"ground", &"tree", &"gate"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate"]
		}
	).track()
	
	CellItem.new(
		&"tree",
		"res://wfc/items/models/tree.glb",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate"]
		}
	).track()
	
	CellItem.new(
		&"gate",
		"res://wfc/items/models/gate.glb",
		{
			Vector3.RIGHT:   [&"ground"],
			Vector3.LEFT:    [&"ground"],
			Vector3.UP:      [&"air", &"ground"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air"],
			Vector3.FORWARD: [&"air"]
		}
	).track()
	
	wfc = WaveFunctionCollapseGrid.new(10, 5, 10, 4, CellItem.definitions)
	add_child(wfc)
	wfc.collapse_all()
	wfc.spawn_items()
