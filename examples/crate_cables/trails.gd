extends Node2D

const Tiles = preload("tiles.gd")

@onready var main = get_node("%Main")
@onready var floor_layer = get_node("%Floor")
@onready var movement = get_node("%PTMovement")

var trails: PTTiles

# Called once when a level starts
func init_update(_context):
	trails = PTTiles.new()
	trails.copy_tilemap_settings_from(main)
	floor_layer.add_child(trails)

# Called once during each each turn
func frame_update(_context):
	pass

# Called at the end of each turn
func late_frame_update(_context):
	for move in movement.moves_made:
		var dest = Directions.shift_cell(move.cell, move.dir)
		if crate_is_at(dest):
			trails.clear_cell(move.cell)
			trails.stack_tile_at_cell(Tiles.TRAIL, move.cell, move.dir)
		
		if main.has_tile_at_cell(Tiles.PLAYER, dest):
			if not floor_layer.has_tile_at_cell(Tiles.PLAYER_STEP, move.cell):
				floor_layer.stack_tile_at_cell(Tiles.PLAYER_STEP, move.cell)
	pass

func crate_is_at(cell:Vector2i):
	for crate_tile in [Tiles.CRATE, Tiles.CRATE_WIRED]:
		if main.has_tile_at_cell(crate_tile, cell):
			return true
	return false
