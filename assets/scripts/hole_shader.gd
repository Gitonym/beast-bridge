extends Node3D

var shader_material = ShaderMaterial.new()
var player
var camera

func _ready():
	player = get_node("/root/World/Player")
	camera = get_node("/root/World/Player/Camera")
	for child in get_children():
		if child is MeshInstance3D:
			shader_material.shader = load("res://assets/shaders/peek.gdshader")
			child.material_override = shader_material

func _process(_delta):
	shader_material.set("shader_parameter/apex", player.global_position + Vector3(0, 1.2, 0))
	shader_material.set("shader_parameter/base", camera.global_position)
	shader_material.set("shader_parameter/base_radius", 1)
