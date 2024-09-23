# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid
var cell_items: Array[CellItem] = []
# bei rotation: seitenregeln um eins nach rechts verschieben
# verbindungen mit r werden zu f: r>f>l>b>r

func _ready():
	# fixed seed for testing purposed, randomize seed otherwise 3675036171
	var current_seed: int = randi()
	print("Seed: ", current_seed)
	seed(1487596161)
	
	print("Time to create tiles: ", get_execution_time(create_tiles))
	
	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(10, 5, 10, 4, cell_items)			# create a new grid with specified size, pass all items
		add_child(wfc)															# add it to the scene tree
		wfc.collapse_all()														# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called
	
	print("Seed: ", current_seed)


func create_tiles() -> void:
	# base
	cell_items.append(CellItem.new("air", "", "air", "air", "air", "air", "air", "air"))
	cell_items.append(CellItem.new("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground"))
	cell_items.append(CellItem.new("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground"))
	
	# paths
	#cell_items.append(CellItem.new("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground"))
	cell_items.append_array(CellItem.newMirrored("path_straight", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground"))
	#cell_items.append_array(CellItem.newCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground"))
	cell_items.append_array(CellItem.newCardinal("path_bend", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground"))
	#cell_items.append_array(CellItem.newCardinal("path_t", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground"))
	
	# slope
	cell_items.append_array(CellItem.newCardinal("grass_slope_top", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r"))
	cell_items.append_array(CellItem.newCardinal("grass_slope_bottom", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom"))
	cell_items.append_array(CellItem.newCardinal("grass_slope_top_corner", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r"))
	cell_items.append_array(CellItem.newCardinal("grass_slope_bottom_corner", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r"))
	cell_items.append_array(CellItem.newCardinal("slope_wall", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r"))
	cell_items.append_array(CellItem.newCardinal("slope_corner", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r"))
	
	# connectors
	cell_items.append_array(CellItem.newCardinal("slope_grass_connector", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground"))
	cell_items.append_array(CellItem.newCardinal("slope_grass_corner_connector", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground"))

# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
