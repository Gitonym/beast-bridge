extends Node3D

@export var grid_size: int = 32
@export var cell_size = 2

var highlight_scene = preload("res://assets/ui/cell_highlight/highlight.tscn")
var highlight_instance = null

var grid = []
var selected_x = null
var selected_y = null

func _ready():
	init_array()
	highlight_instance = highlight_scene.instantiate()
	highlight_instance.scale = Vector3(2, 1, 2)
	add_child(highlight_instance)

func _process(_delta):
	highlight_selected()

func init_array():
	for y in range(grid_size):
		grid.append([])
		for x in range(grid_size):
			grid.append(null)

func highlight_selected():
	if selected_x != null and selected_y != null:
		highlight_instance.position.x = selected_x * cell_size
		highlight_instance.position.z = selected_y * cell_size
		highlight_instance.visible = true
	else:
		highlight_instance.visible = false

func select(x, y):
	if x < grid_size and x >= 0:
		if y < grid_size and y >= 0:
			selected_x = x
			selected_y = y

func coordinates_to_index(x, z):
	return Vector2((x/cell_size) % grid_size, (z/cell_size) % grid_size)
