extends Node2D

const CRATE = 2
const CURSOR = 6
const CURSOR_ACTIVE = 7

@onready var grid = get_node("%Grid")
@onready var lines = get_node("%Lines")

# Called once when a level starts
func init_update(context):
	context.cursor_cell = null
	context.previous_mouse_cell = null
	context.dragging = false
	pass

# Called once during each frame
func frame_update(context):
	if context.frame_key == Inputs.MOUSE_DOWN:
		if grid.has_tile_at_cell(CRATE, context.mouse_cell):
			context.dragging = true
	
	if context.frame_key == Inputs.MOUSE_UP:
		context.dragging = false
	
	if context.frame_key == Inputs.MOUSE_MOVE:
		context.previous_mouse_cell = context.cursor_cell
	pass

# Called at the end of each frame
func late_frame_update(context):
	if context.cursor_cell != null:
		lines.remove_tile_from_cell(CURSOR, context.cursor_cell)
		lines.remove_tile_from_cell(CURSOR_ACTIVE, context.cursor_cell)
	
	context.cursor_cell = context.mouse_cell
	lines.stack_tile_at_cell(get_cursor(context), context.cursor_cell)
	pass

func get_cursor(context):
	if context.dragging:
		return CURSOR_ACTIVE
	else:
		return CURSOR
