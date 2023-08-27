extends Node2D

@onready var grid: PTTiles = get_node("%Grid")

const GRASS = 0
const DIRT = 1
const CRATE = 2
const TARGET = 3
const WALL = 4

# Called once during each frame
func frame_update(context):	
	if context.dragging and context.frame.key == Inputs.MOUSE_MOVE:
		if cell_is_free(context.frame.mouse_cell):
			grid.remove_tile_from_cell(CRATE, context.previous_mouse_cell)
			grid.stack_tile_at_cell(CRATE, context.frame.mouse_cell)
			context.next_player_cell = context.previous_mouse_cell
		else:
			context.frame.force_release_mouse = true
			context.dragging = false
	pass


func cell_is_free(cell:Vector2i)->bool:
	return not grid.has_tile_at_cell(WALL, cell) and not grid.has_tile_at_cell(CRATE, cell)
