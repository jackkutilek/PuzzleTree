@tool
extends Resource
class_name PuzzleTreeProject

@export var base_grid_size: Vector2i: set = _set_base_grid_size
@export var grid_layers: Array[Dictionary]: set = _set_grid_layers
@export var levels: Array[Dictionary]: set = _set_levels
@export var world_layout: String: set = _set_world_layout

func _set_base_grid_size(value):
	if base_grid_size != value:
		base_grid_size = value
		emit_changed()

func _set_grid_layers(value):
	if grid_layers != value:
		grid_layers = value
		emit_changed()

func _set_levels(value):
	if levels != value:
		levels = value
		emit_changed()

func _set_world_layout(value):
	if world_layout != value:
		world_layout = value
		emit_changed()
	
