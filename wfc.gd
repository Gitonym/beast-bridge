extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	CellItem.new(&"air",
		"",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"ramp"]
		}).track()
	
	CellItem.new(&"ground",
		"res://wfc/items/models/cube.glb",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
			Vector3.UP:      [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"]
		}).track()
	
	CellItem.new(&"tree",
		"res://wfc/items/models/tree.glb",
		{
			Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
			Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"ramp"]
		}).track()
	
	CellItem.new(&"gate",
		"res://wfc/items/models/gate.glb",
		{
			Vector3.RIGHT:   [&"ground", &"ramp"],
			Vector3.LEFT:    [&"ground", &"ramp"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air"],
			Vector3.FORWARD: [&"air"]
		}).track().generate_rotations()
	
	CellItem.new(&"water",
		"res://wfc/items/models/water.glb",
		{
			Vector3.RIGHT:   [&"ground", &"water", &"ramp"],
			Vector3.LEFT:    [&"ground", &"water", &"ramp"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"ground", &"water", &"ramp"],
			Vector3.FORWARD: [&"ground", &"water", &"ramp"]
		}).track()
	
	CellItem.new(&"ramp",
		"res://wfc/items/models/ramp.glb",
		{
			Vector3.RIGHT:   [&"ground", &"water", &"ramp", &"gate"],
			Vector3.LEFT:    [&"air", &"tree"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"ground", &"tree", &"air"],
			Vector3.FORWARD: [&"ground", &"tree", &"air"]
		}).track().generate_rotations()
	
	wfc = WaveFunctionCollapseGrid.new(15, 5, 15, 4, CellItem.definitions)
	add_child(wfc)
	wfc.collapse_all()
	wfc.spawn_items()
