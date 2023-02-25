extends Node2D

const TILE_PLAYER = 3
const TILE_CRATE = 4

func frame_update(context:Dictionary):
	var movement = get_node("%PTMovement")
	var colliders = get_node("%Colliders")
	
	var move = movement.get_move_at(colliders, context.player_pos)
	if move != null:
		var dest = Directions.shift_cell(context.player_pos, move.dir)
		if crate_is_at(dest):
			movement.queue_move(colliders, dest, move.dir)

func crate_is_at(cell:Vector2):
	var colliders = get_node("%Colliders")
	return colliders.has_tile_at_cell(TILE_CRATE, cell)
