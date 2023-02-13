tool
extends Resource

export(Dictionary) var data setget set_data

func set_data(value):
	data = value
	emit_changed()
