extends Node2D

@onready var grid = get_node("%Grid")

const CRATE = 2

# Called once during each frame
func frame_update(context):	
	if context.dragging and context.frame_key == Inputs.MOUSE_MOVE:
		grid.remove_tile_from_cell(CRATE, context.cursor_cell)
		grid.stack_tile_at_cell(CRATE, context.mouse_cell)
	pass
