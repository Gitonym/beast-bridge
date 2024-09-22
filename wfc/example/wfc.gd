# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid


func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	# TODO: randomize()
	# TODO: this seed: 2720066666 fails for dimensions of 10, 5, 10
	var current_seed: int = randi()
	print("Seed: ", current_seed)
	seed(current_seed)
	
	var cell_items: Array[CellItem] = [
		CellItem.new("air", "", "air", "air", "air", "air", "air", "air"),
		CellItem.new("ground", "res://wfc/items/models/cube.glb", "ground", "ground", "ground", "ground", "air", "air")
	]

	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(8, 4, 8, 4, cell_items)		# create a new grid with specified size, pass all items
		add_child(wfc)													# add it to the scene tree
		wfc.collapse_all()												# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called


# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
