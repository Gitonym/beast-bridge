# this class represents the grid that stores the results of the wfc
# this class is also responsible for performing the wfc
class_name WaveFunctionCollapseGrid
extends Node3D


var size: Vector3									# dimensions of the grid
var cell_size: float								# the edge length of a cell in meters, this should match with the size of the meshed representing aa cell

var grid											# the 3d grid storing the results
var cell_items: Array[CellItem]						# a list of all possible cellItems

var history: Array = []								# a history for restoring past states of the grid
var modified_stack: Array[int] = []					# keeps track of which cells have been modified

var last_print_time = 0.0							# keeps track of when the last progress bar was printed
var rng = RandomNumberGenerator.new()				# to make random choiced and have them be reproducible through a seed
var state_used: int									# keeps track of the state at the beginning of a generation

var max_iterations = 1000							# the maximum number of iterations a generation can take
var iterations = 0									# keeps track of the current number of iterations
var time_out = 8000									# the amount of time one generation can take at most in milliseconds
var start_time										# keeps track of when the generation started


func _init(p_x_size: int, p_y_size: int, p_z_size: int, p_cell_size: float, p_cell_items: Array[CellItem]):
	randomize_seed()
	cell_items = p_cell_items
	size = Vector3(p_x_size, p_y_size, p_z_size)
	cell_size = p_cell_size
	init_grid()


# inits a 3d array with all cellItems
func init_grid() -> void:
	grid = []
	var _ground_item = get_item_by_name("ground")
	var grass_item = get_item_by_name("grass")
	var air_item = get_item_by_name("air")
	#var _path_straight_item = get_item_by_name("path_straight_x")
	#var path_end_items = CellItem.newCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground")
	
	var grid_size = get_1d_index(size - Vector3.ONE) + 1
	for i in range(grid_size):
		grid.append(cell_items.duplicate())
		
		var i_3d = get_3d_index(i)
		# set the lowest level to always be ground
		#if i_3d.y == 0:
		#	set_cell(i, ground_item)
		
		# TODO: this causes problems
		if i_3d == Vector3(12, 8, 12):
			set_cell(i, grass_item)
			
		# set top to air
		if i_3d.y == size.y - 1:
			set_cell(i, air_item)
			
		# set the lowest level to always be grass
		if i_3d.y == 0 and (i_3d.x == 0 or i_3d.z == 0 or i_3d.x == size.x-1 or i_3d.z == size.z-1):
			set_cell(i, grass_item)
			
		# sets two paths that need to be connected
		#if i_3d == Vector3(0, 0, 1):
		#	set_cell(i, path_end_items[0])
		#if i_3d == Vector3(size.x-1, 0, size.z-2):
		#	set_cell(i, path_end_items[2])
	#set_cell(get_1d_index(Vector3(5, 1, 5)), get_item_by_name("wall_r"))


# calculates the 1d index from a 3d index and returns it
func get_1d_index(index: Vector3) -> int:
	return int(index.x + index.y * size.x + index.z * size.x * size.y);


# calculates a 3d index from a 1d index and returns it
func get_3d_index(index: int) -> Vector3:
	@warning_ignore("integer_division")
	var z: int = index / (int(size.x) * int(size.y));
	@warning_ignore("integer_division")
	var y: int = (index % (int(size.x) * int(size.y))) / int(size.x);
	var x: int = index % int(size.x);
	return Vector3(x, y, z)


# sets the cell to the specified cellItem and adds the index to modified
# TODO: might be better to also add an assumption to the history
func set_cell(index: int, item: CellItem) -> void:
	grid[index] = [item]
	modified_stack.append(index)


func get_item_by_name(item_name: StringName) -> CellItem:
	for item in cell_items:
		if item.item_name == item_name:
			return item
	printerr("No CellItem with the name '" + item_name + "' has been found")
	assert(false)
	return


# return a random cell index with the lowest entropy that is not collapsed yet
func get_min_entropy() -> int:
	var min_entropy: Array[int] = []
	var min_amount: float = -1
	for i in grid.size():
		if grid[i].size() <= 1:
			continue
		var entropy = get_entropy(i)
		if entropy < min_amount or min_amount < 0:
			min_amount = entropy
			min_entropy = [i]
		elif entropy == min_amount:
			min_entropy.append(i)
	return min_entropy[rng.randi_range(0, min_entropy.size()-1)]


# returns the entropy of a given index in the grid
func get_entropy(index: int) -> float:
	var entropy = 0.0
	for item in grid[index]:
		entropy += 1/item.weight
	return entropy

# returns true if all cells contain only one cellItem, false otherwise
func is_grid_collapsed() -> bool:
	for cell in grid:
		if cell.size() > 1:
			return false
	return true


# removes all cellItems from the given index except one random cellItem
# adds the chosen item and removed items to the history in this format:
# [&"assumption", index: int, chosen: CellItem, removed1: CellItem, removed2: CellItem, ...]
func collapse_cell(cell_index: int) -> void:
	var assumption: Array = []
	var choice_index = get_weighted_random_index(grid[cell_index])
	var choice = grid[cell_index][choice_index]
	assumption.push_back(&"assumption")
	assumption.push_back(cell_index)
	assumption.push_back(choice)
	for index in range(grid[cell_index].size()):
		if not choice == grid[cell_index][index]:
			assumption.push_back(grid[cell_index][index])
	grid[cell_index] = [choice]
	history.push_back(assumption)
	modified_stack.push_back(cell_index)


# takes an array of CellItems and returns a random index weighted by the CellItems weight
func get_weighted_random_index(items: Array) -> int:
	var weights = PackedFloat32Array()
	for item in items:
		weights.append(item.weight)
	return rng.rand_weighted(weights)

# collapses the whole grid until all cells contain only one item
func collapse_all() -> void:
	iterations = 0
	start_time = Time.get_ticks_msec()
	state_used = rng.state					#keep track of what state was used to generate this grid
	print("State: ", rng.state)
	
	while not is_grid_collapsed():
		
		iterations += 1
		print_collapsed_percentage()
		if iterations >= max_iterations or Time.get_ticks_msec() - start_time >= time_out:
			retry()
			return
		
		if modified_stack.size() == 0:
			collapse_cell(get_min_entropy())
		propagate()
	print_rich("[color=green]Success[/color] after ", iterations, " iterations and ", Time.get_ticks_msec() - start_time, " milliseconds. Used state: ", state_used)


# checks a given cells neighbours and removes them if they are invalid. the neighbours of any modified cell are also checked
func propagate() -> void:
	while modified_stack.size() > 0:
		var current_1d_index: int = modified_stack.pop_back()
		var current_3d_index: Vector3 = get_3d_index(current_1d_index)
		
		# look in all directions
		for direction in [Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT, Vector3.BACK, Vector3.UP, Vector3.DOWN]:
			# get neighbour index for the current direction
			var neighbour_index = get_1d_index(current_3d_index + direction)
			if not is_valid_index(neighbour_index):
				continue
			if not are_neighbours(current_1d_index, neighbour_index):
				continue
			# get all valid keys for the current direction
			var current_keys: Array[StringName] = []
			for current_item in grid[current_1d_index]:
				if not current_keys.has(current_item.keys[direction]):
					current_keys.append(current_item.keys[direction])
			
			# remove any neighbour that does not fit the keys
			for neighbour in grid[neighbour_index]:
				if not current_keys.has(neighbour.keys[direction*(-1)]):
					grid[neighbour_index].erase(neighbour)
					# add removed neighbour to history in this format:
					# [&"propogation", index Vector3, name: CellItem]
					history.push_back([&"propogation", neighbour_index, neighbour])
					#add neighbour to modifiedStack if not already in the stack
					if not modified_stack.has(neighbour_index):	# TODO: might be worth removing this check
						modified_stack.push_back(neighbour_index)
					# backstep if the last neighbour in the cell was deleted
					if grid[neighbour_index].size() == 0:
						backstep()
						return


func are_neighbours(i1: int, i2: int) -> bool:
	var i1_3d = get_3d_index(i1)
	var i2_3d = get_3d_index(i2)
	return (i1_3d - i2_3d).length() <= 1


# spawns the map after the grid has been collapsed
func spawn_items() -> void:
	if not is_grid_collapsed():
		return
	for i in grid.size():
		var current_item: CellItem = grid[i][0]
		if current_item.scene_path == &"":
			continue
		var instance = load(current_item.scene_path).instantiate()
		instance.position = get_3d_index(i) * cell_size
		if current_item.rotation == Vector3.FORWARD:
			instance.rotate(Vector3.UP, deg_to_rad(90))
		elif current_item.rotation == Vector3.LEFT:
			instance.rotate(Vector3.UP, deg_to_rad(180))
		elif current_item.rotation == Vector3.BACK:
			instance.rotate(Vector3.UP, deg_to_rad(-90))
		add_child(instance)


# checks if the given index is in bounds of the grid array
func is_valid_index(index: int) -> bool:
	return index >= 0 and index < grid.size()

# chekcs if a 3d index is valid
func is_valid_index_3d(index: Vector3) -> bool:
	if index.x < 0 or index.x >= size.x:
		return false
	if index.y < 0 or index.y >= size.y:
		return false
	if index.z < 0 or index.z >= size.z:
		return false
	return true

# pops and handles history items until an assumption was undone
func backstep() -> void:
	while history.size() > 0:
		var history_item: Array = history.pop_back()
		if history_item[0] == &"propogation":
			restore_propogation(history_item)
		elif history_item[0] == &"assumption":
			restore_assumption(history_item)
			return
	printerr("History empty, continuing from state which knowingly fails")


# gets a propagation passed in this form: [&"propogation", index int, name: CellItem]
# restores the state of the grid and modifed_stack as if that propagation was never made
# removes the last history entry if it matches the propagation
func restore_propogation(propagation: Array) -> void:
	var index: int = propagation[1]
	#remove from modified_stack
	#TODO: not sure if this needs to be done. when error investigate here
	if modified_stack.size() > 0 and index == modified_stack[-1]:
		modified_stack.pop_back()
	#restore the cellItem to the grid
	var cell_item = propagation[2]
	grid[index].push_back(cell_item)


# gets an assumption passed in this form: [&"assumption", index: int, chosen: CellItem, removed1: CellItem, removed2: CellItem, ...]
# restores the state of the grid and modifed_stack as if that assumption was never made
# the made assumption gets added to the history so the CellItem gets readded in case more backstepping is required
func restore_assumption(assumption: Array) -> void:
	assumption.pop_front()
	var index: int = assumption.pop_front()
	var choice: CellItem = assumption.pop_front()
	var discarded: Array = assumption
	# push the old decision on the history as propagation
	grid[index] = []
	# TODO: do i want to do this if the history is empty?
	history.push_back([&"propogation", index, choice])
	#restore the removed items
	for discarded_item in discarded:
		grid[index].push_back(discarded_item)
	# mark the cell as modified if only one item has been restored as this is effectively the new choice
	# TODO: might need to do this regardless of how many choices remain, whatever choice was removed needs to be propagated through
	if discarded.size() == 1:
		modified_stack.push_back(index)


func print_collapsed_percentage() -> void:
	if Time.get_ticks_usec() - last_print_time > 100000.0:
		last_print_time = Time.get_ticks_usec()
	else:
		return
	
	
	var all: int = grid.size()
	var all_opt: int = grid.size() * cell_items.size()
	var collapsed: int = 0
	var collapsed_opt: int = 0
	
	for i in range(grid.size()):
		collapsed_opt += grid[i].size()
		if grid[i].size() == 1:
			collapsed += 1
	var result: float = float(collapsed)/float(all)
	var result_opt: float = float(collapsed_opt)/float(all_opt)
	var bar: String = "["
	var bar_opt: String = "["
	for x in range(10, 110, 10):
		if x >= result * 100:
			bar += "░"
		else:
			bar += "▓"
	bar += "]"
	for x in range(10, 110, 10):
		if x >= result_opt * 100:
			bar_opt += "░"
		else:
			bar_opt += "▓"
	bar_opt += "]"
	print("Collapsed: ", bar, " ", int(result * 100), "%", "\t\tOptions: ", bar_opt, " ", int(result_opt * 100), "%")


# in a collapsed grid counts and returns a dict of the occurences of a CellItem and its rotations by name
func count_cells_by_name(item_name: StringName) -> Dictionary:
	var possible_names = [item_name, item_name + "_x", item_name + "_z", item_name + "_r", item_name + "_f", item_name + "_l", item_name + "_b"]
	var results = {
		possible_names[0]: 0,
		possible_names[1]: 0,
		possible_names[2]: 0,
		possible_names[3]: 0,
		possible_names[4]: 0,
		possible_names[5]: 0,
		possible_names[6]: 0
	}
	
	if not is_grid_collapsed():
		printerr("Occurences of CellItems can only be counted in a fully collapsed grid")
		results[&"all"] = 0
		return results
	
	for i in grid:
		for current_name in possible_names:
			if i[0].item_name == current_name:
				results[current_name] += 1
	
	results[&"all"] = 0
	for current_name in possible_names:
		results["all"] += results[current_name]
	return results


# sets a specific seed. if p_seed == 1 does nothing
func set_seed(p_seed: int = -1) -> void:
	if p_seed == -1:
		return
	print("set seed to: ", p_seed)
	rng.seed = p_seed

# sets the state for the next generation
func set_state(state: int) -> void:
	rng.state = state


# sets a random seed
func randomize_seed() -> void:
	rng.randomize()
	print("Random Seed: ", rng.seed)

# restarts the generation
func retry() -> void:
	last_print_time = 0
	print_rich("[color=orange]Retrying[/color] after ", iterations, " iterations and ", Time.get_ticks_msec() - start_time ," milliseconds")
	iterations = 0
	history = []
	modified_stack = []
	init_grid()
	collapse_all()
