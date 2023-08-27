extends Node2D

const PushCrates = preload("pushcrates.gd")

func late_frame_update(context:Dictionary):
	var targets = get_node("%Targets") as PTTiles
	var colliders = get_node("%Colliders") as PTTiles
	
	var winning = true
	for cell in targets.get_all_used_cells():
		var has_crate = colliders.has_tile_at_cell(PushCrates.TILE_CRATE, cell)
		winning = winning and has_crate
		if not winning:
			break
	
	context.frame.winning = winning

