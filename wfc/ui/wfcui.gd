extends Control


func add_button(item_name: StringName, callback: Callable) -> void:
	if item_name != &"air":
		var button_container: HBoxContainer = $ScrollContainer/HBoxContainer
		var button_scene: PackedScene = load("res://wfc/ui/WFCButton.tscn")
		var button = button_scene.instantiate()
		button.set_properties(item_name, callback)
		button_container.add_child(button)
