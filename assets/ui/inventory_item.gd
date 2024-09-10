extends MarginContainer

@onready var inventory = $"../../.."
@export var item_scene: PackedScene


func _on_texture_button_pressed():
	inventory.selected_scene = item_scene
