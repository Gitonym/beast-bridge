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

var history: Array = []					# a history for restoring past states of the grid
var modified_stack: Array[Vector3] = []	# keeps track of which cells have been modified


var template_grid: Array
var template_grid_dimensions: Vector3
var selected_cellItem: CellItem
var selected_cell_index: Vector3 = Vector3(0, 0, 0)
var cursor_instance: Node3D


func _init(_x_size: int, _y_size: int, _z_size: int, _cellSize: float, _cellItems: Array[CellItem]):
	x_size = _x_size
	y_size = _y_size
	z_size = _z_size
	cellSize = _cellSize
	cellItems = _cellItems
	init_grid()


func _process(_delta):
	move_cursor()
	if Input.is_action_just_pressed("enter") and selected_cellItem != null:
		set_template_cell()
	remove_template_cell()
	rotate_template_cell()


# inits a 3d array with all cellItems
func init_grid() -> void:
	grid = []
	for x in range(x_size):
		grid.append([])
		for y in range(y_size):
			grid[x].append([])
			for z in range(z_size):
				grid[x][y].append(cellItems.duplicate())
	##set the lowest y value to "ground" CellItems except the rim
	#for x in range(x_size):
	#	for z in range(z_size):
	#		if (x > 3 and x < x_size - 4) or (z > 3 and z < z_size-4):
	#			set_cell(Vector3(x, 0, z), [cellItems[1]])
	#
	##transition between ground and water
	#for x in range(x_size):
	#	for z in range(z_size):
	#		if (x > 0 and x <= 3) or (z > 0 and z <= 3):
	#			set_cell(Vector3(x, 0, z), [cellItems[1], cellItems[7]])
	#
	##water border
	#for x in range(x_size):
	#	for z in range(z_size):
	#		if x == 0 or x == x_size - 1 or z == 0 or z == z_size-1:
	#			set_cell(Vector3(x, 0, z), [cellItems[7]])


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
						#[&"propogation", index Vector3, name: CellItem]
						history.push_back([&"propogation", neighbour_index, current_neighbour])
						#add neighbour to modifiedStack if not already in the stack
						if not modified_stack.has(neighbour_index):
							modified_stack.push_back(neighbour_index)
				grid[neighbour_index.x][neighbour_index.y][neighbour_index.z] = new_neighbours
				#if a cell is empty then backstep
				if new_neighbours.size() == 0:
					backstep()
					return


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


# creates a floor under the template grid so there is something to click on
func create_template_ground():
	var body = StaticBody3D.new()
	var mesh = MeshInstance3D.new()
	var coll = CollisionShape3D.new()
	
	mesh.position = Vector3(0.5, -0.5, 0.5)
	mesh.mesh = BoxMesh.new()
	coll.position = Vector3(0.5, -0.5, 0.5)
	coll.shape = BoxShape3D.new()
	
	body.add_child(mesh)
	body.add_child(coll)
	
	body.scale = Vector3(template_grid_dimensions.x * cellSize, 1, template_grid_dimensions.z * cellSize)
	
	add_child(body)


# call this to prepare a scene so you can edit rules manually
func template_mode(width: int, height: int, length: int) -> void:
	template_grid_dimensions = Vector3(width, height, length)
	create_cursor()
	create_template_ground()
	init_template_grid()
	create_template_ui()


# creates the cursor scene visualizer
func create_cursor() -> void:
	cursor_instance = load("res://wfc/ui/cursor.tscn").instantiate()
	cursor_instance.scale = Vector3(cellSize, cellSize, cellSize)
	cursor_instance.position = selected_cell_index * cellSize
	add_child(cursor_instance)


func init_template_grid() -> void:
	template_grid = []
	for x in range(template_grid_dimensions.x):
		template_grid.append([])
		for y in range(template_grid_dimensions.y):
			template_grid[x].append([])
			for z in range(template_grid_dimensions.z):
				template_grid[x][y].append({"cellItem": null, "instance": null})


func _unhandled_input(event):
	if event.is_action_pressed("click"):
		position_to_index(get_mouse_position_3d())


# shoots a ray from the camera to the mouse until something is hit
# the coordinates of the hit position are returned
func get_mouse_position_3d():
	var viewport := get_viewport()
	var mouse_position := viewport.get_mouse_position()
	var camera := viewport.get_camera_3d()
	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)
	var ray_length := camera.far
	var end := origin + direction * ray_length
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var result := space_state.intersect_ray(query)
	var mouse_position_3D:Vector3 = result.get("position", end)
	print("x: ", mouse_position_3D.x, "\ty: ", mouse_position_3D.y, "\tz: ", mouse_position_3D.z)
	return Vector3(mouse_position_3D.x, mouse_position_3D.y, mouse_position_3D.z)


# creates the ui and populates it with buttons
func create_template_ui() -> void:
	var ui = load("res://wfc/ui/WFCUI.tscn").instantiate()
	add_child(ui)
	for item in cellItems:
		ui.add_button(item.item_name, _set_selected_cellItem)


# the callback that is passed to the ui, a button uses this callback when its pressed
func _set_selected_cellItem(item_name: StringName):
	for item in cellItems:
		if item.item_name == item_name:
			selected_cellItem = item
			print(selected_cellItem.item_name)
			return
	printerr("No matching CellItem found for ", item_name)


# converts a Vector3 of a position into the corresponding index of the template_grid
# returns Vector3(-1, -1, -1) if outside of grid
func position_to_index(pos: Vector3) -> Vector3:
	var index: Vector3 = Vector3(
		int(fmod(pos.x, template_grid_dimensions.x)),
		int(fmod(pos.y, template_grid_dimensions.y)),
		int(fmod(pos.z, template_grid_dimensions.z))
	)
	
	if pos.x >= template_grid_dimensions.x * cellSize or pos.x < 0:
		index = Vector3(-1, -1, -1)
	if pos.y >= template_grid_dimensions.y * cellSize or pos.y < 0:
		index = Vector3(-1, -1, -1)
	if pos.z >= template_grid_dimensions.z * cellSize or pos.z < 0:
		index = Vector3(-1, -1, -1)
		
	print("index: ", index)
	return index


# moves the cursor
# TODO: cursor wraps in positive directions only
func move_cursor() -> void:
	if Input.is_action_just_pressed("move_right"):
		selected_cell_index += Vector3.RIGHT
	if Input.is_action_just_pressed("move_left"):
		selected_cell_index += Vector3.LEFT
	if Input.is_action_just_pressed("move_forward"):
		selected_cell_index += Vector3.FORWARD
	if Input.is_action_just_pressed("move_back"):
		selected_cell_index += Vector3.BACK
	if Input.is_action_just_pressed("jump"):
		selected_cell_index += Vector3.UP
	if Input.is_action_just_pressed("sprint"):
		selected_cell_index += Vector3.DOWN
	selected_cell_index = Vector3(
		max(0, fmod(selected_cell_index.x, template_grid_dimensions.x)),
		max(0, fmod(selected_cell_index.y, template_grid_dimensions.y)),
		max(0, fmod(selected_cell_index.z, template_grid_dimensions.z))
	)
	update_cursor_position()


# sets the position of the cursor scene to the position of the selected cell
func update_cursor_position() -> void:
	if cursor_instance != null:
		cursor_instance.position = selected_cell_index * cellSize


# spawns an item in the current cell if its empty and enter was pressed
func set_template_cell() -> void:
	if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] == null:
		template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] = selected_cellItem.clone()
		spawn_template_cell(selected_cell_index)


func remove_template_cell() -> void:
	if Input.is_action_just_pressed("delete"):
		if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] != null:
			template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] = null
			remove_child(template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"])
			template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"] = null


func spawn_template_cell(index: Vector3) -> void:
	var current_item = template_grid[index.x][index.y][index.z]["cellItem"]
	
	if current_item.item_name != &"air":
		var instance = load(current_item.model_path).instantiate()
		instance.position = Vector3(index.x * cellSize, index.y * cellSize, index.z * cellSize)
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
		template_grid[index.x][index.y][index.z]["instance"] = instance
		instance.position += Vector3.BACK * cellSize # TODO: fix the item origins so this hack can be removed


# TODO: fix the rotation
func rotate_template_cell() -> void:
	if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] == null:
		return
	if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"] == null:
		return
	var instance = template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"]
	if Input.is_action_just_pressed("right"):
				remove_child(instance)
				template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"].rotation = Vector3.RIGHT
				spawn_template_cell(selected_cell_index)
	if Input.is_action_just_pressed("left"):
				remove_child(instance)
				template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"].rotation = Vector3.LEFT
				spawn_template_cell(selected_cell_index)
	if Input.is_action_just_pressed("up"):
				remove_child(instance)
				template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"].rotation = Vector3.FORWARD
				spawn_template_cell(selected_cell_index)
	if Input.is_action_just_pressed("down"):
				remove_child(instance)
				template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"].rotation = Vector3.BACK
				spawn_template_cell(selected_cell_index)
