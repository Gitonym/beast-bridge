class_name WaveFunctionCollapseTemplate
extends Node3D


var cellSize: float						# the edge length of a cell in meters, this should match with the size of the meshed representing aa cell
var cellItems: Array[CellItem]			# a list of all possible cellItems
var template_grid: Array
var template_grid_dimensions: Vector3
var selected_cellItem: CellItem
var selected_cell_index: Vector3 = Vector3(0, 0, 0)
var cursor_instance: Node3D


func _init(_template_grid_dimensions: Vector3, _cellSize: float, _cellItems: Array[CellItem]):
	template_grid_dimensions = _template_grid_dimensions
	cellSize = _cellSize
	cellItems = _cellItems


func _process(_delta):
	move_cursor()
	if Input.is_action_just_pressed("enter") and selected_cellItem != null:
		set_template_cell()
	remove_template_cell()
	rotate_template_cell()


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
func start() -> void:
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
