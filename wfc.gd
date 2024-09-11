extends Node3D

var wfc: WaveFunctionCollapseGrid


# Called when the node enters the scene tree for the first time.
func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	# TODO: randomize()
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
	
	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(20, 5, 20, 4, CellItem.definitions)
		add_child(wfc)
		wfc.collapse_all()
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")
	
	print("Rotations: ", wfc.count_rotations(&"ramp"))
	print("Rotations: ", wfc.count_rotations(&"gate"))


# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
