# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid


func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	# TODO: randomize()
	seed(12345)
	var cell_items: Array[CellItem] = []	# all possible items will be stored in here
	
	# manually create an item with all its possible neighbours
	cell_items.append(
		CellItem.new(&"air",
			"",
			{
				Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.UP:      [&"air"],
				Vector3.DOWN:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
				Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"ramp"]
			}
		)
	)
	
	cell_items.append(
		CellItem.new(&"ground",
			"res://wfc/items/models/cube.glb",
			{
				Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
				Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
				Vector3.UP:      [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
				Vector3.DOWN:    [&"ground"],
				Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"],
				Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"water", &"ramp"]
			}
		)
	)
	
	cell_items.append(	
		CellItem.new(&"tree",
			"res://wfc/items/models/tree.glb",
			{
				Vector3.RIGHT:   [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.LEFT:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.UP:      [&"air"],
				Vector3.DOWN:    [&"ground"],
				Vector3.BACK:    [&"air", &"ground", &"tree", &"gate", &"ramp"],
				Vector3.FORWARD: [&"air", &"ground", &"tree", &"gate", &"ramp"]
			}
		)
	)
	
	# manually create an item and add it to the array
	# this item can also have different orientations so we call generate_rotations()
	#generate rotations returns an array of all rotations so we use append_array() here
	cell_items.append_array(	
		CellItem.new(&"gate",
			"res://wfc/items/models/gate.glb",
			{
				Vector3.RIGHT:   [&"ground"],
				Vector3.LEFT:    [&"ground"],
				Vector3.UP:      [&"air"],
				Vector3.DOWN:    [&"ground"],
				Vector3.BACK:    [&"air"],
				Vector3.FORWARD: [&"air"]
			}
		).generate_rotations()	# this generates three more CellItems with different rotations
	)
	
	cell_items.append(	
		CellItem.new(&"water",
			"res://wfc/items/models/water.glb",
			{
				Vector3.RIGHT:   [&"ground", &"water"],
				Vector3.LEFT:    [&"ground", &"water"],
				Vector3.UP:      [&"air"],
				Vector3.DOWN:    [&"ground"],
				Vector3.BACK:    [&"ground", &"water"],
				Vector3.FORWARD: [&"ground", &"water"]
			}
		)
	)
	
	cell_items.append_array(	
		CellItem.new(&"ramp",
			"res://wfc/items/models/ramp.glb",
			{
				Vector3.RIGHT:   [&"ground", &"water"],
				Vector3.LEFT:    [&"air", &"tree"],
				Vector3.UP:      [&"air"],
				Vector3.DOWN:    [&"ground"],
				Vector3.BACK:    [&"ground", &"air"],
				Vector3.FORWARD: [&"ground", &"air"]
			}
		).generate_rotations()
	)

	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(20, 5, 20, 4, cell_items)	# create a new grid with specified size, pass all items
		add_child(wfc)													# add it to the scene tree
		wfc.collapse_all()												# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called
	
	print("Rotations: ", wfc.count_rotations(&"ramp"))
	print("Rotations: ", wfc.count_rotations(&"gate"))


# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
