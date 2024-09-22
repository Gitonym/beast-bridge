# This script shows a usage example of the WaveFunctionCollapse system
extends Node3D

# first create the grid
var wfc: WaveFunctionCollapseGrid

# bei rotation: seitenregeln um eins nach rechts verschieben
# verbindungen mit r werden zu f: r>f>l>b>r

func _ready():
	# fixed seed for testing purposed, randomize seed otherwise
	var current_seed: int = randi()
	print("Seed: ", current_seed)
	seed(current_seed)
	
	var cell_items: Array[CellItem] = [
		CellItem.new("air", "", "air", "air", "air", "air", "air", "air"),
		CellItem.new("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground"),
		CellItem.new("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground"),
		
		# paths
		CellItem.new("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground"),
		
		CellItem.new("path_straight_x", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground"),
		CellItem.new("path_straight_z", "res://wfc/tiles/path_straight.glb", "grass", "path", "grass", "path", "air", "ground", Vector3.FORWARD),
		
		CellItem.new("path_end_r", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground"),
		CellItem.new("path_end_f", "res://wfc/tiles/path_end.glb", "grass", "path", "grass", "grass", "air", "ground", Vector3.FORWARD),
		CellItem.new("path_end_l", "res://wfc/tiles/path_end.glb", "grass", "grass", "path", "grass", "air", "ground", Vector3.LEFT),
		CellItem.new("path_end_b", "res://wfc/tiles/path_end.glb", "grass", "grass", "grass", "path", "air", "ground", Vector3.BACK),
		
		CellItem.new("path_bend_r", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground"),
		CellItem.new("path_bend_f", "res://wfc/tiles/path_bend.glb", "grass", "path", "path", "grass", "air", "ground", Vector3.FORWARD),
		CellItem.new("path_bend_l", "res://wfc/tiles/path_bend.glb", "grass", "grass", "path", "path", "air", "ground", Vector3.LEFT),
		CellItem.new("path_bend_b", "res://wfc/tiles/path_bend.glb", "path", "grass", "grass", "path", "air", "ground", Vector3.BACK),
		
		CellItem.new("path_t_r", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground"),
		CellItem.new("path_t_f", "res://wfc/tiles/path_t.glb", "path", "path", "path", "grass", "air", "ground", Vector3.FORWARD),
		CellItem.new("path_t_l", "res://wfc/tiles/path_t.glb", "grass", "path", "path", "path", "air", "ground", Vector3.LEFT),
		CellItem.new("path_t_b", "res://wfc/tiles/path_t.glb", "path", "grass", "path", "path", "air", "ground", Vector3.BACK),
		
		# slope top
		CellItem.new("grass_slope_top_r", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r"),
		CellItem.new("grass_slope_top_f", "res://wfc/tiles/grass_slope_top.glb", "slope_top_f", "grass", "slope_top_f", "air", "air", "edge_f", Vector3.FORWARD),
		CellItem.new("grass_slope_top_l", "res://wfc/tiles/grass_slope_top.glb", "air", "slope_top_l", "grass", "slope_top_l", "air", "edge_l", Vector3.LEFT),
		CellItem.new("grass_slope_top_b", "res://wfc/tiles/grass_slope_top.glb", "slope_top_b", "air", "slope_top_b", "grass", "air", "edge_b", Vector3.BACK),
		
		# slope top path
		CellItem.new("grass_slope_top_path_r", "res://wfc/tiles/grass_slope_top_path.glb", "path", "slope_top_r", "air", "slope_top_r", "air", "ladder_r"),
		CellItem.new("grass_slope_top_path_f", "res://wfc/tiles/grass_slope_top_path.glb", "slope_top_f", "path", "slope_top_f", "air", "air", "ladder_f", Vector3.FORWARD),
		CellItem.new("grass_slope_top_path_l", "res://wfc/tiles/grass_slope_top_path.glb", "air", "slope_top_l", "path", "slope_top_l", "air", "ladder_l", Vector3.LEFT),
		CellItem.new("grass_slope_top_path_b", "res://wfc/tiles/grass_slope_top_path.glb", "slope_top_b", "air", "slope_top_b", "path", "air", "ladder_b", Vector3.BACK),
		
		# slope bottom
		CellItem.new("grass_slope_bottom_r", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom"),
		CellItem.new("grass_slope_bottom_f", "res://wfc/tiles/grass_slope_bottom.glb", "slope_bottom_f", "ground", "slope_bottom_f", "air", "edge_f", "slope_bottom", Vector3.FORWARD),
		CellItem.new("grass_slope_bottom_l", "res://wfc/tiles/grass_slope_bottom.glb", "air", "slope_bottom_l", "ground", "slope_bottom_l", "edge_l", "slope_bottom", Vector3.LEFT),
		CellItem.new("grass_slope_bottom_b", "res://wfc/tiles/grass_slope_bottom.glb", "slope_bottom_b", "air", "slope_bottom_b", "ground", "edge_b", "slope_bottom", Vector3.BACK),
		
		# slope bottom path
		CellItem.new("grass_slope_bottom_path_r", "res://wfc/tiles/grass_slope_bottom_path.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "ladder_r", "slope_bottom"),
		CellItem.new("grass_slope_bottom_path_f", "res://wfc/tiles/grass_slope_bottom_path.glb", "slope_bottom_f", "ground", "slope_bottom_f", "air", "ladder_f", "slope_bottom", Vector3.FORWARD),
		CellItem.new("grass_slope_bottom_path_l", "res://wfc/tiles/grass_slope_bottom_path.glb", "air", "slope_bottom_l", "ground", "slope_bottom_l", "ladder_l", "slope_bottom", Vector3.LEFT),
		CellItem.new("grass_slope_bottom_path_b", "res://wfc/tiles/grass_slope_bottom_path.glb", "slope_bottom_b", "air", "slope_bottom_b", "ground", "ladder_b", "slope_bottom", Vector3.BACK),
		
		# slope top corner
		CellItem.new("grass_slope_top_corner_r", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r"),
		CellItem.new("grass_slope_top_corner_f", "res://wfc/tiles/grass_slope_top_corner.glb", "air", "slope_top_l", "slope_top_f", "air", "air", "corner_f", Vector3.FORWARD),
		CellItem.new("grass_slope_top_corner_l", "res://wfc/tiles/grass_slope_top_corner.glb", "air", "air", "slope_top_b", "slope_top_l", "air", "corner_l", Vector3.LEFT),
		CellItem.new("grass_slope_top_corner_b", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_b", "air", "air", "slope_top_r", "air", "corner_b", Vector3.BACK),
		
		# slope bottom corner
		CellItem.new("grass_slope_bottom_corner_r", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r"),
		CellItem.new("grass_slope_bottom_corner_r", "res://wfc/tiles/grass_slope_bottom_corner.glb", "air", "slope_bottom_l", "slope_bottom_f", "air", "corner_f", "slope_bottom_corner_f", Vector3.FORWARD),
		CellItem.new("grass_slope_bottom_corner_r", "res://wfc/tiles/grass_slope_bottom_corner.glb", "air", "air", "slope_bottom_b", "slope_bottom_l", "corner_l", "slope_bottom_corner_l", Vector3.LEFT),
		CellItem.new("grass_slope_bottom_corner_r", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_b", "air", "air", "slope_bottom_r", "corner_b", "slope_bottom_corner_b", Vector3.BACK),
		
		# slope wall
		CellItem.new("slope_wall_r", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r"),
		CellItem.new("slope_wall_f", "res://wfc/tiles/slope_wall.glb", "edge_f", "ground", "edge_f", "air", "edge_f", "edge_f", Vector3.FORWARD),
		CellItem.new("slope_wall_l", "res://wfc/tiles/slope_wall.glb", "air", "edge_l", "ground", "edge_l", "edge_l", "edge_l", Vector3.LEFT),
		CellItem.new("slope_wall_b", "res://wfc/tiles/slope_wall.glb", "edge_b", "air", "edge_b", "ground", "edge_b", "edge_b", Vector3.BACK),
		
		# slope wall path
		CellItem.new("slope_wall_path_r", "res://wfc/tiles/slope_wall_path.glb", "ground", "edge_r", "air", "edge_r", "ladder_r", "ladder_r"),
		CellItem.new("slope_wall_path_f", "res://wfc/tiles/slope_wall_path.glb", "edge_f", "ground", "edge_f", "air", "ladder_f", "ladder_f", Vector3.FORWARD),
		CellItem.new("slope_wall_path_l", "res://wfc/tiles/slope_wall_path.glb", "air", "edge_l", "ground", "edge_l", "ladder_l", "ladder_l", Vector3.LEFT),
		CellItem.new("slope_wall_path_b", "res://wfc/tiles/slope_wall_path.glb", "edge_b", "air", "edge_b", "ground", "ladder_b", "ladder_b", Vector3.BACK),
		
		# slope corner
		CellItem.new("slope_corner_r", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r"),
		CellItem.new("slope_corner_f", "res://wfc/tiles/slope_corner.glb", "air", "edge_f", "edge_f", "air", "corner_f", "corner_f", Vector3.FORWARD),
		CellItem.new("slope_corner_l", "res://wfc/tiles/slope_corner.glb", "air", "air", "edge_l", "edge_l", "corner_l", "corner_l", Vector3.LEFT),
		CellItem.new("slope_corner_b", "res://wfc/tiles/slope_corner.glb", "edge_b", "air", "air", "edge_b", "corner_b", "corner_b", Vector3.BACK),
		
		# slope grass connector
		CellItem.new("slope_grass_connector_r", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground"),
		CellItem.new("slope_grass_connector_f", "res://wfc/tiles/ground.glb", "slope_grass_connector", "ground", "slope_grass_connector", "grass", "slope_bottom", "ground"),
		CellItem.new("slope_grass_connector_l", "res://wfc/tiles/ground.glb", "grass", "slope_grass_connector", "ground", "slope_grass_connector", "slope_bottom", "ground"),
		CellItem.new("slope_grass_connector_b", "res://wfc/tiles/ground.glb", "slope_grass_connector", "grass", "slope_grass_connector", "ground", "slope_bottom", "ground"),
		
		# slope grass corner connector
		CellItem.new("slope_grass_corner_connector_r", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground"),
		CellItem.new("slope_grass_corner_connector_f", "res://wfc/tiles/ground.glb", "grass", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom_corner_f", "ground"),
		CellItem.new("slope_grass_corner_connector_l", "res://wfc/tiles/ground.glb", "grass", "grass", "slope_grass_connector", "slope_grass_connector", "slope_bottom_corner_l", "ground"),
		CellItem.new("slope_grass_corner_connector_b", "res://wfc/tiles/ground.glb", "slope_grass_connector", "grass", "grass", "slope_grass_connector", "slope_bottom_corner_b", "ground"),
	]

	print("Time to generate: ", get_execution_time(func ():
		wfc = WaveFunctionCollapseGrid.new(10, 5, 10, 4, cell_items)			# create a new grid with specified size, pass all items
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
