extends MarginContainer


var callback: Callable


func set_properties(item_name: StringName, cb: Callable) -> void:
	var label: Label = $TextureButton/Label
	label.text = item_name
	callback = cb


func _on_texture_button_pressed():
	var label: Label = $TextureButton/Label
	callback.call(label.text)
