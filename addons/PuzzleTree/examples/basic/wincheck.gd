extends Node2D

const PushCrates = preload("pushcrates.gd")

func late_frame_update(context:Dictionary):
	var targets = get_node("%Targets")
	var colliders = get_node("%Colliders")
	
	var winning = true
	for cell in targets.get_all_used_cells():
		var tile = colliders.get_tile_at_cell(cell)
		winning = winning and tile == PushCrates.TILE_CRATE
		if not winning:
			break
	
	context.winning = winning

