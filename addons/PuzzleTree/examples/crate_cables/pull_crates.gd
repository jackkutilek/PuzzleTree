extends Node2D

const Tiles = preload("tiles.gd")

onready var main = get_node("%Main")

# Called once when a level starts
func init_update(context):
	context.spawn_crate_at = null

# Called once during each each turn
func frame_update(context):
	context.spawn_crate_at = null
	
	var movement = get_node("%PTMovement")
	var move = movement.get_move_at(main, context.player_pos)
	if move != null:
		var check_cell = Directions.shift_cell(context.player_pos, Directions.opposite(move.dir))
		if main.has_tile_at_cell(Tiles.CRATE_WIRED, check_cell):
			context.spawn_crate_at = context.player_pos

# Called at the end of each turn
func late_frame_update(context):
	if context.spawn_crate_at != null and not main.has_tile_at_cell(Tiles.PLAYER, context.spawn_crate_at):
		main.stack_tile_at_cell(Tiles.CRATE, context.spawn_crate_at)

func crate_is_at(cell:Vector2):
	for crate_tile in [Tiles.CRATE, Tiles.CRATE_WIRED]:
		if main.has_tile_at_cell(crate_tile, cell):
			return true
	return false
