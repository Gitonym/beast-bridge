class_name WaveFunctionCollapseGrid
extends Node3D


var x_size: int
var y_size: int
var z_size: int
var cellSize: float

var grid
var cellItems: Array[CellItem]

var tempNode: Node3D


func _init(_x_size: int, _y_size: int, _z_size: int, _cellSize: float, _cellItems: Array[CellItem]):
	x_size = _x_size
	y_size = _y_size
	z_size = _z_size
	cellSize = _cellSize
	cellItems = _cellItems.duplicate()
	init_grid()
	
	tempNode = Node3D.new()
	add_child(tempNode)


#inits a 3d array with all cellItems
func init_grid() -> void:
	grid = []
	for x in range(x_size):
		grid.append([])
		for y in range(y_size):
			grid[x].append([])
			for z in range(z_size):
				grid[x][y].append(cellItems.duplicate())
	
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
func collapse_cell(cell_index: Vector3) -> void:
	grid[cell_index.x][cell_index.y][cell_index.z].shuffle()
	while grid[cell_index.x][cell_index.y][cell_index.z].size() > 1:
		grid[cell_index.x][cell_index.y][cell_index.z].pop_back()


#checks a given cells neighbours and removes them if they are invalid. the neighbours of any modified cell are also checked
func propagate(cell_index: Vector3) -> void:
	var modified_stack: Array[Vector3] = [cell_index]
	while modified_stack.size() > 0:
		var current_index: Vector3 = modified_stack.pop_back()
		var directions: Array[Vector3] = [
			Vector3(1, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(0, 1, 0),
			Vector3(0, -1, 0),
			Vector3(0, 0, 1),
			Vector3(0, 0, -1),
		]
		for direction: Vector3 in directions:
			#find all valid neighbours of the current cell
			var neighbour_index: Vector3 = current_index + direction
			var allowed_neighbours: Array[StringName] = []
			for current_item: CellItem in grid[current_index.x][current_index.y][current_index.z]:
				allowed_neighbours.append_array(current_item.get_valid_neighbours_for_direction(direction))
			
			#remove any invalid neigbour
			if is_valid_index(neighbour_index):
				var new_neighbours: Array = grid[neighbour_index.x][neighbour_index.y][neighbour_index.z].duplicate()
				for current_neighbour: CellItem in grid[neighbour_index.x][neighbour_index.y][neighbour_index.z]:
					if not allowed_neighbours.has(current_neighbour.item_name):
						new_neighbours.erase(current_neighbour)
						#add neighbour to modifiedStack if not already in the stack
						if not modified_stack.has(neighbour_index):
							modified_stack.push_back(neighbour_index)
				#TODO: remove the assert
				assert(new_neighbours.size() > 0)
				grid[neighbour_index.x][neighbour_index.y][neighbour_index.z] = new_neighbours


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
