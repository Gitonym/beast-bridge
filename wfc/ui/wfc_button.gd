extends MarginContainer


func set_label(item_name: StringName) -> void:
	var label: Label = $TextureButton/Label
	label.text = item_name
