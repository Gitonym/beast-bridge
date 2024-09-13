# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid


func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	# TODO: randomize()
	seed(12347)
	
	var rules_file = FileAccess.open("res://wfc/temp/rules.json", FileAccess.READ)
	var rules_json: String = rules_file.get_as_text()

	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(10, 5, 10, 4, rules_json)	# create a new grid with specified size, pass all items
		add_child(wfc)													# add it to the scene tree
		wfc.collapse_all()												# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called
	
	# print("Rotations: ", wfc.count_rotations(&"ramp"))
	# print("Rotations: ", wfc.count_rotations(&"gate"))


# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
