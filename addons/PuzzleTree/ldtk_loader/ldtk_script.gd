@tool
extends Resource

@export var data: Dictionary : set = set_data

func set_data(value):
	if value != data:
		data = value
		emit_changed()
