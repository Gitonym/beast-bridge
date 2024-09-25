# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid
var cell_items: Array[CellItem] = []
# bei rotation: seitenregeln um eins nach rechts verschieben
# verbindungen mit r werden zu f: r>f>l>b>r

func _ready():
	print("Time to create tiles: ", get_execution_time(create_tiles))
	
	wfc = WaveFunctionCollapseGrid.new(15, 6, 15, 4, cell_items)				# create a new grid with specified size, pass all items
	wfc.set_seed()										# -8998448832981343625
	wfc.set_state(-100963415562136908)
	
	print("Time to generate: ", get_execution_time(func ():
		add_child(wfc)															# add it to the scene tree
		wfc.collapse_all()														# run the wfc algorythm
	), " Seconds")
	
	print("Time to spawn: ", get_execution_time(wfc.spawn_items), " Seconds")	# spawn_items spawns all scenes from the grid after collapse_all was called
	


func create_tiles() -> void:
	# base
	cell_items.append(CellItem.new("air", "", "air", "air", "air", "air", "air", "air", 0.0))
	cell_items.append(CellItem.new("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground", 3.0))
	cell_items.append(CellItem.new("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground", 5.0))
	
	# paths
	cell_items.append(CellItem.new("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground", 0.0))
	cell_items.append_array(CellItem.newMirrored("path_straight", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground", 0.0))
	#cell_items.append_array(CellItem.newCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground", 0.0))
	cell_items.append_array(CellItem.newCardinal("path_bend", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground", 0.0))
	#cell_items.append_array(CellItem.newCardinal("path_t", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground", 0.0))
	
	# slope
	cell_items.append_array(CellItem.newCardinal("grass_slope_top", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r"))
	cell_items.append_array(CellItem.newCardinal("grass_slope_bottom", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom"))
	cell_items.append_array(CellItem.newCardinal("grass_slope_top_corner", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r", 0.5))
	cell_items.append_array(CellItem.newCardinal("grass_slope_bottom_corner", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r", 0.5))
	cell_items.append_array(CellItem.newCardinal("slope_wall", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r"))
	cell_items.append_array(CellItem.newCardinal("slope_corner", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r"))
	
	# connectors
	cell_items.append_array(CellItem.newCardinal("slope_grass_connector", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground"))
	cell_items.append_array(CellItem.newCardinal("slope_grass_corner_connector", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground"))
	
	# walls
	#cell_items.append_array(CellItem.newCardinal("wall", "res://wfc/tiles/wall.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall"))
	#cell_items.append_array(CellItem.newCardinal("door", "res://wfc/tiles/door.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall"))
	#cell_items.append_array(CellItem.newCardinal("wall_inside_corner", "res://wfc/tiles/wall_inside_corner.glb", "air", "air", "wall_edge_f", "wall_edge_r", "air", "wall", 0.1))
	#Better results without this item: cell_items.append_array(CellItem.newCardinal("wall_outside_corner", "res://wfc/tiles/wall_outside_corner.glb", "wall_edge_f", "wall_edge_r", "air", "air", "air", "wall"))
	
	#cell_items.append_array(CellItem.newCardinal("foundation_edge", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_edge", "grass", "foundation_edge", "wall", "ground"))
	#cell_items.append_array(CellItem.newCardinal("foundation_corner", "res://wfc/tiles/ground.glb", "foundation_edge", "foundation_edge", "grass", "grass", "wall", "ground"))
	#cell_items.append(CellItem.new("foundation_inside", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_inside", "foundation_inside", "foundation_inside", "air", "ground"))

# executes the callback and returns a float in seconds measuring how long the execution took
func get_execution_time(callback: Callable) -> float:
	var time1 = Time.get_ticks_usec()
	callback.call()
	var time2 = Time.get_ticks_usec()
	return (time2-time1)/1000000.0
