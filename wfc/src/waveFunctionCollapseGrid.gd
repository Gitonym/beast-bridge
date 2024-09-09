class_name WaveFunctionCollapseGrid
extends Node3D


var x_size: int
var y_size: int
var z_size: int
var cellSize: float

var grid
var cellItems: Array[CellItem]

var history: Array = []
var modified_stack: Array[Vector3] = []


func _init(_x_size: int, _y_size: int, _z_size: int, _cellSize: float, _cellItems: Array[CellItem]):
	x_size = _x_size
	y_size = _y_size
	z_size = _z_size
	cellSize = _cellSize
	cellItems = _cellItems
	init_grid()


#inits a 3d array with all cellItems
func init_grid() -> void:
	grid = []
	for x in range(x_size):
		grid.append([])
		for y in range(y_size):
			grid[x].append([])
			for z in range(z_size):
				grid[x][y].append(cellItems)
	
	#set the lowest y value to "ground" CellItems
	for x in range(x_size):
		for z in range(z_size):
			set_cell(Vector3(x, 0, z), cellItems[1])


#return the cell index with the lowest entropy that is not collapsed yet
func get_min_entropy() -> Vector3:
	var min_entropy: Vector3 = Vector3(-1, -1, -1)
	var min_amount: int = -1
	for x in range(x_size):
		for y in range(y_size):
			for z in range(z_size):
				if (grid[x][y][z].size() < min_amount and grid[x][y][z].size() > 1) or (min_amount == -1 and grid[x][y][z].size() > 1):
					min_amount = grid[x][y][z].size()
					min_entropy.x = x
					min_entropy.y = y
					min_entropy.z = z
					if min_amount == 2:
						return min_entropy
	return min_entropy


#returns true if all cells contain only one cellItem, false otherwise
func is_collapsed() -> bool:
	for x in range(x_size):
		for y in range(y_size):
			for z in range(z_size):
				if grid[x][y][z].size() > 1:
					return false
	return true


#removes all cellItems from the given index except one random cellItem
#adds the chosen item and removed items to the history in this format:
#[&"assumption", index: Vector3, chosen: StringName, removed1: StringName, removed2: StringName, ...]
func collapse_cell(cell_index: Vector3) -> void:
	var assumption: Array = []
	grid[cell_index.x][cell_index.y][cell_index.z].shuffle()
	while grid[cell_index.x][cell_index.y][cell_index.z].size() > 1:
		assumption.push_back(grid[cell_index.x][cell_index.y][cell_index.z].pop_back().item_name)
	assumption.push_front(grid[cell_index.x][cell_index.y][cell_index.z][0].item_name)
	assumption.push_front(cell_index)
	assumption.push_front(&"assumption")
	history.push_back(assumption)


#checks a given cells neighbours and removes them if they are invalid. the neighbours of any modified cell are also checked
func propagate(cell_index: Vector3) -> void:
	modified_stack.push_back(cell_index)
	while modified_stack.size() > 0:
		var current_index: Vector3 = modified_stack.pop_back()
		var directions: Array[Vector3] = [
			Vector3.RIGHT,
			Vector3.LEFT,
			Vector3.UP,
			Vector3.DOWN,
			Vector3.BACK,
			Vector3.FORWARD,
		]
		for direction: Vector3 in directions:
			#find all valid neighbours of the current cell
			var neighbour_index: Vector3 = current_index + direction
			var allowed_neighbours: Array[StringName] = []
			for current_item: CellItem in grid[current_index.x][current_index.y][current_index.z]:
				allowed_neighbours.append_array(current_item.valid_neighbours[direction])
			
			#remove any invalid neigbour
			#TODO: can be moved further up to improve performance
			if is_valid_index(neighbour_index):
				var new_neighbours: Array = grid[neighbour_index.x][neighbour_index.y][neighbour_index.z].duplicate()
				for current_neighbour: CellItem in grid[neighbour_index.x][neighbour_index.y][neighbour_index.z]:
					if not allowed_neighbours.has(current_neighbour.item_name):
						new_neighbours.erase(current_neighbour)
						#add removed neighbour to history in this format:
						#[&"propogation", index Vector3, name: StringName]
						history.push_back([&"propogation", neighbour_index, current_neighbour.item_name])
						#add neighbour to modifiedStack if not already in the stack
						if not modified_stack.has(neighbour_index):
							modified_stack.push_back(neighbour_index)
				grid[neighbour_index.x][neighbour_index.y][neighbour_index.z] = new_neighbours
				#if a cell is empty then backstep
				if new_neighbours.size() == 0:
					backstep()
					return


#collapses the whole grid until all cells contain only one item
func collapse_all() -> void:
	var current_cell: Vector3
	while not is_collapsed():
		current_cell = get_min_entropy()
		collapse_cell(current_cell)
		propagate(current_cell)


#spawns the map after the grid has been collapsed
func spawn_items() -> void:
	var loaded_items: Dictionary 
	if is_collapsed():
		var current_item: CellItem
		for x in range(x_size):
			for y in range(y_size):
				for z in range(z_size):
					current_item = grid[x][y][z][0]
					if current_item.item_name != &"air":
						if not loaded_items.has(current_item.model_path):
							loaded_items[current_item.item_name] = load(current_item.model_path)
						var instance = loaded_items[current_item.item_name].instantiate()
						instance.position = Vector3(x * cellSize, y * cellSize, z * cellSize)
						add_child(instance)


#sets a cell to a specific item and propogates to the neighbours
func set_cell(cell_index: Vector3, cell_item: CellItem) -> void:
	grid[cell_index.x][cell_index.y][cell_index.z] = [cell_item]
	propagate(cell_index)


#checks if the given index is in bounds of the grid array
func is_valid_index(index: Vector3) -> bool:
	if index.x < 0 or index.y < 0 or index.z < 0:
		return false
	if index.x >= x_size or index.y >= y_size or index.z >= z_size:
		return false
	return true


func backstep() -> void:
	while history.size() > 0:
		var history_item: Array = history.pop_back()
		var history_type: StringName = history_item.pop_front()
		if history_type == &"propogation":
			restore_propogation(history_item)
		elif history_type == &"assumption":
			restore_assumption(history_item)
			return


func restore_propogation(history_item: Array) -> void:
	var index: Vector3 = history_item.pop_front()
	#remove from modified_stack
	#TODO: not sure if this needs to be done. when error investigate here
	if modified_stack.size() > 0 and index == modified_stack[-1]:
		modified_stack.pop_back()
	#restore in cell
	var history_name = history_item[0]
	for item in CellItem.definitions:
		if item.item_name == history_name:
			grid[index.x][index.y][index.z].push_back(item)


func restore_assumption(history_item: Array) -> void:
	var index: Vector3 = history_item.pop_front()
	var choice: StringName = history_item.pop_front()
	var discarded: Array = history_item
	#remove old decision
	#the old discarded decision push on history as propagation
	grid[index.x][index.y][index.z].pop_back()
	history.push_back([&"propogation", index, choice])
	#restore the removed items
	for discarded_item in discarded:
		for item in CellItem.definitions:
			if item.item_name == discarded_item:
				grid[index.x][index.y][index.z].push_back(item)
