# this class represents the grid that stores the results of the wfc
# this class is also responsible for performing the wfc
class_name WaveFunctionCollapseGrid
extends Node3D


var x_size: int							# width of the grid
var y_size: int							# length of the grid
var z_size: int							# height of the grid
var cellSize: float						# the edge length of a cell in meters, this should match with the size of the meshed representing aa cell

var grid								# the 3d grid storing the results
var cellItems: Array[CellItem]			# a list of all possible cellItems
var rules = []

var history: Array = []					# a history for restoring past states of the grid
var modified_stack: Array[Vector3] = []	# keeps track of which cells have been modified


func _init(_x_size: int, _y_size: int, _z_size: int, _cellSize: float, rules_json: String):
	x_size = _x_size
	y_size = _y_size
	z_size = _z_size
	cellSize = _cellSize
	generate_cell_items_and_rules_from_json(rules_json)
	init_grid()


func generate_cell_items_and_rules_from_json(rules_json: String) -> void:
	var parsed_rules = JSON.parse_string(rules_json)
	generate_cell_items_from_json(parsed_rules["items"])
	generate_rules_from_json(parsed_rules["rules"])


func generate_rules_from_json(rules_list: Array) -> void:
	rules = []
	for rule in rules_list:
		var new_rule: Array = [[[null, null, null], [null, null, null], [null, null, null]], [[null, null, null], [null, null, null], [null, null, null]], [[null, null, null], [null, null, null], [null, null, null]]]
		var list_index: int = 0
		for z in range(3):
			for y in range(3):
				for x in range(3):
					var item_name: StringName = rule[list_index]["item_name"]
					var item_rotation: Vector3 = Vector3(rule[list_index]["rotation_x"], rule[list_index]["rotation_y"], rule[list_index]["rotation_y"])
					for cellItem in cellItems:
						if cellItem.item_name == item_name and cellItem.rotation == item_rotation:
							new_rule[x][y][z] = cellItem
					list_index += 1
		rules.append(new_rule)


func generate_cell_items_from_json(cellItems_json) -> void:
	cellItems = []
	for cellItem_json in cellItems_json:
		cellItems.append(CellItem.new(
			cellItem_json["item_name"],
			cellItem_json["scene_path"],
			cellItem_json["rotatable"]
		))
		# generate the othe rotations if rotatable
		if cellItem_json["rotatable"]:
			cellItems.append(CellItem.new(
				cellItem_json["item_name"],
				cellItem_json["scene_path"],
				cellItem_json["rotatable"],
				Vector3(-1, 0, 0)
			))
			cellItems.append(CellItem.new(
				cellItem_json["item_name"],
				cellItem_json["scene_path"],
				cellItem_json["rotatable"],
				Vector3(0, 0, 1)
			))
			cellItems.append(CellItem.new(
				cellItem_json["item_name"],
				cellItem_json["scene_path"],
				cellItem_json["rotatable"],
				Vector3(0, 0, -1)
			))


# inits a 3d array with all cellItems
func init_grid() -> void:
	grid = []
	for x in range(x_size):
		grid.append([])
		for y in range(y_size):
			grid[x].append([])
			for z in range(z_size):
				grid[x][y].append(cellItems.duplicate())


# return a random cell index with the lowest entropy that is not collapsed yet
func get_min_entropy() -> Vector3:
	var min_entropy: Array[Vector3] = []
	var min_amount: int = -1
	for z in range(z_size):
		for y in range(y_size):
			for x in range(x_size):
				if (grid[x][y][z].size() < min_amount or min_amount == -1) and grid[x][y][z].size() > 1:
					min_amount = grid[x][y][z].size()
					min_entropy = [Vector3(x, y, z)]
					# TODO: small optimization might make the probability of rotation assymetric though, more investigation required before reenabling
					#if min_amount == 2:
					#	return min_entropy.pick_random()
				elif (grid[x][y][z].size() == min_amount):
					min_entropy.append(Vector3(x, y, z))
	return min_entropy.pick_random()


# returns true if all cells contain only one cellItem, false otherwise
func is_collapsed() -> bool:
	return for_each_cell_in_grid(func is_cell_collapsed(x, y, z):
		if grid[x][y][z].size() > 1:
			return false
		return true
	)


# removes all cellItems from the given index except one random cellItem
# adds the chosen item and removed items to the history in this format:
# [&"assumption", index: Vector3, chosen: CellItem, removed1: CellItem, removed2: CellItem, ...]
func collapse_cell(cell_index: Vector3) -> void:
	var assumption: Array = []
	grid[cell_index.x][cell_index.y][cell_index.z].shuffle()
	while grid[cell_index.x][cell_index.y][cell_index.z].size() > 1:
		assumption.push_back(grid[cell_index.x][cell_index.y][cell_index.z].pop_back())
	assumption.push_front(grid[cell_index.x][cell_index.y][cell_index.z][0])
	assumption.push_front(cell_index)
	assumption.push_front(&"assumption")
	history.push_back(assumption)


# checks a given cells neighbours and removes them if they are invalid. the neighbours of any modified cell are also checked
func propagate(cell_index: Vector3) -> void:
	modified_stack.push_back(cell_index)
	while modified_stack.size() > 0:
		var current_index: Vector3 = modified_stack.pop_back()
		
		# find all valid neighbours for the current index
		var valid_neighbours: Array = [[[[], [], []], [[], [], []], [[], [], []]], [[[], [], []], [[], [], []], [[], [], []]], [[[], [], []], [[], [], []], [[], [], []]]]
		# for every rule
		for rule in rules:
			# for every possible item at current index
			for item in grid[current_index.x][current_index.y][current_index.z]:
				# if rule applies
				if item.equals(rule[1][1][1]):
					# for every cell in the rule
					for z in range(3):
						for y in range(3):
							for x in range(3):
								# save as valid neighbour if not already saved
								if !valid_neighbours[x][y][z].has(rule[x][y][z]):
									valid_neighbours[x][y][z].append(rule[x][y][z])
							
		
		# remove any invalid neigbour
		# for every neighbour
		for z in range(3):
			for y in range(3):
				for x in range(3):
					var neighbour_index = Vector3(current_index.x+x-1, current_index.y+y-1, current_index.z+z-1)
					if is_valid_index(neighbour_index) and Vector3(x, y, z) != Vector3(1, 1, 1):
						var new_neighbours: Array = grid[neighbour_index.x][neighbour_index.y][neighbour_index.z].duplicate()
						for current_neighbour: CellItem in grid[neighbour_index.x][neighbour_index.y][neighbour_index.z]:
							if not valid_neighbours[x][y][z].has(current_neighbour):
								new_neighbours.erase(current_neighbour)
								#add removed neighbour to history in this format:
								#[&"propogation", index Vector3, name: CellItem]
								history.push_back([&"propogation", neighbour_index, current_neighbour])
								#add neighbour to modifiedStack if not already in the stack
								if not modified_stack.has(neighbour_index):
									modified_stack.push_back(neighbour_index)
						grid[neighbour_index.x][neighbour_index.y][neighbour_index.z] = new_neighbours
						#if a cell is empty then backstep
						# TODO: can be done sooner
						if new_neighbours.size() == 0:
							backstep()
							return


# checks a given cells neighbours and removes them if they are invalid. the neighbours of any modified cell are also checked
#func propagate(cell_index: Vector3) -> void:
#	modified_stack.push_back(cell_index)
#	while modified_stack.size() > 0:
#		var current_index: Vector3 = modified_stack.pop_back()
#		var directions: Array[Vector3] = [
#			Vector3.RIGHT,
#			Vector3.LEFT,
#			Vector3.UP,
#			Vector3.DOWN,
#			Vector3.BACK,
#			Vector3.FORWARD,
#		]
#		for direction: Vector3 in directions:
#			#find all valid neighbours of the current cell
#			var neighbour_index: Vector3 = current_index + direction
#			var allowed_neighbours: Array[StringName] = []
#			for current_item: CellItem in grid[current_index.x][current_index.y][current_index.z]:
#				allowed_neighbours.append_array(current_item.valid_neighbours[direction])
#			
#			#remove any invalid neigbour
#			#TODO: can be moved further up to improve performance
#			if is_valid_index(neighbour_index):
#				var new_neighbours: Array = grid[neighbour_index.x][neighbour_index.y][neighbour_index.z].duplicate()
#				for current_neighbour: CellItem in grid[neighbour_index.x][neighbour_index.y][neighbour_index.z]:
#					if not allowed_neighbours.has(current_neighbour.item_name):
#						new_neighbours.erase(current_neighbour)
#						#add removed neighbour to history in this format:
#						#[&"propogation", index Vector3, name: CellItem]
#						history.push_back([&"propogation", neighbour_index, current_neighbour])
#						#add neighbour to modifiedStack if not already in the stack
#						if not modified_stack.has(neighbour_index):
#							modified_stack.push_back(neighbour_index)
#				grid[neighbour_index.x][neighbour_index.y][neighbour_index.z] = new_neighbours
#				#if a cell is empty then backstep
#				if new_neighbours.size() == 0:
#					backstep()
#					return


# collapses the whole grid until all cells contain only one item
func collapse_all() -> void:
	var current_cell: Vector3
	while not is_collapsed():
		current_cell = get_min_entropy()
		collapse_cell(current_cell)
		propagate(current_cell)


# spawns the map after the grid has been collapsed
func spawn_items() -> void:
	if is_collapsed():
		for_each_cell_in_grid(func spawn_cell(x, y, z):
			var current_item: CellItem = grid[x][y][z][0]
			if current_item.item_name != &"air":
				var instance = load(current_item.model_path).instantiate()
				instance.position = Vector3(x * cellSize, y * cellSize, z * cellSize)
				if current_item.rotation == Vector3.FORWARD:
					instance.rotate(Vector3.UP, deg_to_rad(90))
					instance.position += Vector3(1, 0, 0) * cellSize
				elif current_item.rotation == Vector3.LEFT:
					instance.rotate(Vector3.UP, deg_to_rad(180))
					instance.position += Vector3(1, 0, -1) * cellSize
				elif current_item.rotation == Vector3.BACK:
					instance.rotate(Vector3.UP, deg_to_rad(-90))
					instance.position += Vector3(0, 0, -1) * cellSize
				add_child(instance)
			return true
		)


# sets a cell to a specific item and propogates to the neighbours
#set cell should only be used max once on any cell
func set_cell(cell_index: Vector3, cell_items: Array[CellItem]) -> void:
	grid[cell_index.x][cell_index.y][cell_index.z] = cell_items
	propagate(cell_index)


# checks if the given index is in bounds of the grid array
func is_valid_index(index: Vector3) -> bool:
	if index.x < 0 or index.y < 0 or index.z < 0:
		return false
	if index.x >= x_size or index.y >= y_size or index.z >= z_size:
		return false
	return true


# pops and handles history items until an assumption was undone
func backstep() -> void:
	while history.size() > 0:
		var history_item: Array = history.pop_back()
		var history_type: StringName = history_item.pop_front()
		if history_type == &"propogation":
			restore_propogation(history_item)
		elif history_type == &"assumption":
			restore_assumption(history_item)
			return
	printerr("History empty, continuing from state which knowingly fails")


# gets a propagation passed in this form: [&"propogation", index Vector3, name: CellItem]
# restores the state of the grid and modifed_stack as if that propagation was never made
# removes the last history entry if it matches the propagation
func restore_propogation(history_item: Array) -> void:
	var index: Vector3 = history_item.pop_front()
	#remove from modified_stack
	#TODO: not sure if this needs to be done. when error investigate here
	if modified_stack.size() > 0 and index == modified_stack[-1]:
		modified_stack.pop_back()
	#restore in cell
	var history_cell_item = history_item[0]
	grid[index.x][index.y][index.z].push_back(history_cell_item)


# gets an assumption passed in this form: [&"assumption", index: Vector3, chosen: CellItem, removed1: CellItem, removed2: CellItem, ...]
# restores the state of the grid and modifed_stack as if that assumption was never made
# the made assumption gets added to the history so the CellItem gets readded in case more backstepping is required
func restore_assumption(history_item: Array) -> void:
	var index: Vector3 = history_item.pop_front()
	var choice: CellItem = history_item.pop_front()
	var discarded: Array = history_item
	#remove old decision
	#the old discarded decision push on history as propagation
	grid[index.x][index.y][index.z].pop_back()
	history.push_back([&"propogation", index, choice])
	#restore the removed items
	for discarded_item in discarded:
		grid[index.x][index.y][index.z].push_back(discarded_item)


# counts the occurences of a specific CellItem in a collapsed grid
func count_rotations(item_name: StringName) -> Array:
	var results: Array = [item_name, {Vector3.RIGHT: 0, Vector3.FORWARD: 0, Vector3.LEFT: 0, Vector3.BACK: 0}]
	
	if !is_collapsed():
		return results
		
	for_each_cell_in_grid(func count_rotation_in_cell(x, y, z):
		var current_item = grid[x][y][z][0]
		if current_item.item_name == item_name:
			results[1][current_item.rotation] += 1
		return true
		)
	return results


# executes callback with the parameters (x, y, z) for every cell and its coordinates
# returns true if no early return, returns false if early return
# the callback should also return true if no ealry return, false if early return
func for_each_cell_in_grid(callback: Callable) -> bool:
	for z in range(z_size):
		for y in range(y_size):
			for x in range(x_size):
				if !callback.call(x, y, z):
					return false
	return true
