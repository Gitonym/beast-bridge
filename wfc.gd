extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	#randomize()
	seed(12345)
	
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
			Vector3.RIGHT:   [&"ground"],
			Vector3.LEFT:    [&"ground"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"air"],
			Vector3.FORWARD: [&"air"]
		}).track().generate_rotations()
	
	CellItem.new(&"water",
		"res://wfc/items/models/water.glb",
		{
			Vector3.RIGHT:   [&"ground", &"water"],
			Vector3.LEFT:    [&"ground", &"water"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"ground", &"water"],
			Vector3.FORWARD: [&"ground", &"water"]
		}).track()
	
	CellItem.new(&"ramp",
		"res://wfc/items/models/ramp.glb",
		{
			Vector3.RIGHT:   [&"ground", &"water"],
			Vector3.LEFT:    [&"air", &"tree"],
			Vector3.UP:      [&"air"],
			Vector3.DOWN:    [&"ground"],
			Vector3.BACK:    [&"ground", &"air"],
			Vector3.FORWARD: [&"ground", &"air"]
		}).track().generate_rotations()
	
	var start = Time.get_ticks_usec()
	
	wfc = WaveFunctionCollapseGrid.new(20, 5, 20, 4, CellItem.definitions)
	add_child(wfc)
	wfc.collapse_all()
	
	var end = Time.get_ticks_usec()
	print("Execution time:")
	print((end-start)/1000000.0, " μs")
	
	wfc.spawn_items()
	
	print(wfc.count_rotations(&"ramp"))
	print(wfc.count_rotations(&"gate"))
