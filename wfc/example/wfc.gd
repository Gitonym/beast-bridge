# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid


func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	# TODO: randomize()
	var current_seed: int = randi()
	print("Seed: ", current_seed)
	seed(current_seed)
	
	var cell_items: Array[CellItem] = [
		CellItem.new("air", "", "air", "air", "air", "air", "air", "air"),
		CellItem.new("road_bend", "res://wfc/items/models/roads/road_bend.glb", "pavement", "pavement", "road", "road", "air", "air"),
		CellItem.new("road_cross", "res://wfc/items/models/roads/road_crossing.glb", "road", "road", "road", "road", "air", "air"),
		CellItem.new("road_dead", "res://wfc/items/models/roads/road_dead.glb", "pavement", "road", "pavement", "pavement", "air", "air"),
		CellItem.new("road_pavement", "res://wfc/items/models/roads/road_pavement.glb", "pavement", "pavement", "pavement", "pavement", "air", "air"),
		CellItem.new("road_straight", "res://wfc/items/models/roads/road_straight.glb", "road", "pavement", "road", "pavement", "air", "air"),
		CellItem.new("road_t", "res://wfc/items/models/roads/road_t.glb", "pavement", "road", "road", "road", "air", "air"),
	]

	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(10, 4, 10, 5, cell_items)			# create a new grid with specified size, pass all items
		add_child(wfc)															# add it to the scene tree
		wfc.collapse_all()														# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called


# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
