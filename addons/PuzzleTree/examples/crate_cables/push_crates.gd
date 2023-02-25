extends Node2D

const Tiles = preload("tiles.gd")

func frame_update(context:Dictionary):
	var movement = get_node("%PTMovement")
	var main = get_node("%Main")
	
	var move = movement.get_move_at(main, context.player_pos)
	if move != null:
		var dest = Directions.shift_cell(context.player_pos, move.dir)
		if crate_is_at(dest):
			movement.copy_move_to(move, dest)

func crate_is_at(cell:Vector2):
	var main = get_node("%Main")
	for crate_tile in [Tiles.CRATE, Tiles.CRATE_WIRED]:
		if main.has_tile_at_cell(crate_tile, cell):
			return true
	return false
