class_name WaveFunctionCollapseTemplate
extends Node3D


var cellSize: float						# the edge length of a cell in meters, this should match with the size of the meshed representing aa cell
var cellItems: Array[CellItem]			# a list of all possible cellItems
var template_grid: Array
var template_grid_dimensions: Vector3
var selected_cellItem: CellItem
var selected_cell_index: Vector3 = Vector3(0, 0, 0)
var cursor_instance: Node3D

var ui


func _init(_template_grid_dimensions: Vector3, _cellSize: float, _cellItems: Array[CellItem]):
	template_grid_dimensions = _template_grid_dimensions
	cellSize = _cellSize
	cellItems = _cellItems


func _ready():
	create_cursor()
	create_template_ground()
	init_template_grid()
	create_template_ui()


func _process(_delta):
	move_cursor()
	if Input.is_action_just_pressed("enter") and selected_cellItem != null:
		set_template_cell()
	remove_template_cell()
	rotate_template_cell()
	if Input.is_action_just_pressed("generate"):
		var template_json: String = generate_template_json()
		save_template_json(template_json)
		var rules: Array[WaveFunctionCollapseRule] = generate_rules()
		var rules_json: String = generate_rules_json(rules)
		save_rules_json(rules_json)


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


# re-creates the ui and populates it with buttons
func create_template_ui() -> void:
	if ui != null:
		remove_child(ui)
	
	ui = load("res://wfc/ui/WFCUI.tscn").instantiate()
	add_child(ui)
	for item in cellItems:
		ui.add_button(item.item_name, _set_selected_cellItem)


# the callback that is passed to the ui, a button uses this callback when its pressed
func _set_selected_cellItem(item_name: StringName):
	for item in cellItems:
		if item.item_name == item_name:
			selected_cellItem = item
			return
	printerr("No matching CellItem found for ", item_name)


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


# remove the instance and CellItem at the current cursor position
func remove_template_cell() -> void:
	if Input.is_action_just_pressed("delete"):
		if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] != null:
			template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] = null
			remove_child(template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"])
			template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"] = null


# spawn the instance of the CellItem at the given index
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


# deletes and recreated the instance of the current CellItem with the correct rotation
func rotate_template_cell() -> void:
	if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"] == null:
		return
	if template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["instance"] == null:
		return
	if !template_grid[selected_cell_index.x][selected_cell_index.y][selected_cell_index.z]["cellItem"].rotatable:
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


# look at the whole grid and generate rules
func generate_rules() -> Array[WaveFunctionCollapseRule]:
	var rules: Array[WaveFunctionCollapseRule] = []
	
	# for every 3x3 sub grid
	# x, y, z is in the center of each sub grid
	for z in range(0, template_grid_dimensions.z - 2, 3):
		for y in range(0, template_grid_dimensions.y - 2, 3):
			for x in range(0, template_grid_dimensions.x - 2, 3):
				# new empty rule
				var sub_grid: Array = [[[null, null, null], [null, null, null], [null, null, null]], [[null, null, null], [null, null, null], [null, null, null]], [[null, null, null], [null, null, null], [null, null, null]]]
				# for every cell in the sub grid
				for dz in range(0, 3):
					for dy in range(0, 3):
						for dx in range(0, 3):
							# save the CellItem in the new rule
							if template_grid[x+dx][y+dy][z+dz]["cellItem"] != null:
								sub_grid[dx][dy][dz] = template_grid[x+dx][y+dy][z+dz]["cellItem"]
							else:
								sub_grid[dx][dy][dz] = cellItems[0]
				# set the new rule
				rules.append(WaveFunctionCollapseRule.new(sub_grid))
	return rules


# takes the rules and converts them to json
func generate_rules_json(rules: Array[WaveFunctionCollapseRule]) -> String:
	var data = {"items": [], "rules": []}
	
	# save all CellItem variations
	for item in cellItems:
		data["items"].append({"item_name": item.item_name, "scene_path": item.model_path, "rotatable": item.rotatable})
	
	# save all rules
	for rule in rules:
		var new_rule = []
		for z in range(3):
			for y in range(3):
				for x in range(3):
					new_rule.append({
						"item_name": rule.rule[x][y][z].item_name,
						"rotation_x": rule.rule[x][y][z].rotation.x,
						"rotation_y": rule.rule[x][y][z].rotation.y,
						"rotation_z": rule.rule[x][y][z].rotation.z
					})
		data["rules"].append(new_rule)
	
	# convert to json and save to file
	return JSON.stringify(data, "    ")


# takes rules as json and saves them to file
func save_rules_json(json_data: String) -> void:
	var file = FileAccess.open("res://wfc/temp/rules.json", FileAccess.WRITE)
	file.store_string(json_data)
	file.close()


# returns a json string that describes the template grid as it curently is
func generate_template_json() -> String:
	var data = {"items": [], "cells": []}
	
	# save all CellItem variations
	for item in cellItems:
		data["items"].append({"item_name": item.item_name, "scene_path": item.model_path, "rotatable": item.rotatable})
	
	for z in range(template_grid_dimensions.z):
		for y in range(template_grid_dimensions.y):
			for x in range(template_grid_dimensions.x):
				if template_grid[x][y][z]['cellItem'] != null:
					var cellItem = template_grid[x][y][z]['cellItem']
					data["cells"].append({
						"item_name": cellItem.item_name,
						"rotation_x": cellItem.rotation.x,
						"rotation_y": cellItem.rotation.y,
						"rotation_z": cellItem.rotation.z,
						"x": x,
						"y": y,
						"z": z
					})
				else:
					data["cells"].append({
						"item_name": cellItems[0].item_name,
						"rotation_x": cellItems[0].rotation.x,
						"rotation_y": cellItems[0].rotation.y,
						"rotation_z": cellItems[0].rotation.z,
						"x": x,
						"y": y,
						"z": z
					})
					
				
	return JSON.stringify(data, "    ")


# takes grid as json and saves them to file
func save_template_json(json_data: String) -> void:
	var file = FileAccess.open("res://wfc/temp/template.json", FileAccess.WRITE)
	file.store_string(json_data)
	file.close()


# loads the template state from file as json and parses it
# restores all cellItems and the state of teh grid
func restore_template_from_file() -> void:
	var file = FileAccess.open("res://wfc/temp/template.json", FileAccess.READ)
	var template_json: String = file.get_as_text()
	var template = JSON.parse_string(template_json)
	restore_cell_items(template["items"])
	restore_template_cells(template["cells"])


func restore_cell_items(items) -> void:
	cellItems = []
	for cellItem_json in items:
		cellItems.append(CellItem.new(
			cellItem_json["item_name"],
			cellItem_json["scene_path"],
			cellItem_json["rotatable"]
		))
	create_template_ui()


func restore_template_cells(cells) -> void:
	for cell in cells:
		var x: int = cell["x"]
		var y: int = cell["y"]
		var z: int = cell["z"]
		var item_name: StringName = cell["item_name"]
		var item_rotation: Vector3 = Vector3(cell["rotation_x"], cell["rotation_y"], cell["rotation_z"])
		
		for item in cellItems:
			if item_name == cellItems[0].item_name:
				template_grid[x][y][z]["cellItem"] = null
				template_grid[x][y][z]["instance"] = null
				item.rotation = item_rotation
				continue
				
			if item.item_name == item_name:
				template_grid[x][y][z]["cellItem"] = item.clone()
				template_grid[x][y][z]["instance"] = null
				item.rotation = item_rotation
				spawn_template_cell(Vector3(x, y, z))
				continue
