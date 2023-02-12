extends TileMap

class_name PTTiles, "../icons/PTTiles.png"

const Directions = preload("../utils/directions.gd")

var submap
var parentmap

# --------------------------------------------------------------------------------------------------

func stack_tile_at_cell(tile, cell: Vector2, dir = null):
	if any_tile_at_cell(cell):
		if submap == null:
			_spawn_submap()
		submap.stack_tile_at_cell(tile, cell, dir)
	else:
		set_tile_at_cell(tile, cell, dir)

func remove_tile_from_cell(tile, cell:Vector2, dir = null):
	var tile_match = get_cellv(cell) == tile
	var dir_match = dir == null or get_dir_at_cell(cell) == dir
	if tile_match and dir_match:
		set_tile_at_cell(-1, cell)
		var subtile = -1
		if submap != null:
			subtile = submap._pull_tile_up_one_submap(cell)
			set_tile_at_cell(subtile, cell)
	else:
		if submap != null:
			submap.remove_tile_from_cell(tile, cell)
		else:
			print("trying to remove tile from a tilemap that doesn't have it")

func replace_tile_at_cell(replace, with, cell, replace_dir=null, with_dir=null):
	remove_tile_from_cell(replace, cell, replace_dir)
	stack_tile_at_cell(with, cell, with_dir)

func clear_cell(cell:Vector2):
	set_cellv(cell, -1)
	if submap != null:
		submap.clear_cell(cell)

func clear_layer():
	clear()
	if submap != null:
		submap.clear_layer()

# --------------------------------------------------------------------------------------------------

func get_tiles_at_cell(cell:Vector2):
	var tiles = []
	get_tiles_at_cell_recursive(cell, tiles)
	return tiles
func get_tiles_at_cell_recursive(cell:Vector2, tiles:Array):
	var tile = get_tile_at_cell(cell)
	if tile != -1:
		tiles.append(tile)
		if submap != null:
			submap.get_tiles_at_cell_recursive(cell, tiles)
	return tiles

func get_tile_dir_at_cell(tile, cell:Vector2):
	if get_tile_at_cell(cell) == tile:
		var xflip = is_cell_x_flipped(int(cell.x), int(cell.y))
		var yflip = is_cell_y_flipped(int(cell.x), int(cell.y))
		var transpose = is_cell_transposed(int(cell.x), int(cell.y))
		var dir = Directions.get_tile_dir(xflip, yflip, transpose)
		return dir
	if submap != null:
		return submap.get_tile_dir_at_cell(tile, cell)
	return null

func is_empty_at_cell(cell:Vector2):
	if get_cellv(cell) != -1:
		return false
	if submap != null and not submap.is_empty_at_cell(cell):
		return false
	return true

func has_tile_at_cell(tile, cell:Vector2):
	if get_cellv(cell) == tile:
		return true
	if submap != null and submap.has_tile_at_cell(tile, cell):
		return true
	return false

func any_tile_at_cell(cell:Vector2):
	return not is_empty_at_cell(cell)

func get_cells_with_tile(tile):
	var cells = get_used_cells_by_id(tile)
	if submap != null:
		var subcells = submap.get_cells_with_tile(tile)
		for subcell in subcells:
			if not cells.has(subcell):
				cells.append(subcell)
	return cells

# --------------------------------------------------------------------------------------------------

func get_tile_at_cell(cell:Vector2):
	return get_cellv(cell)

func set_tile_at_cell(tile, cell:Vector2, dir = null):
	if dir != null:
		var settings = Directions.get_tile_settings(dir)
		set_cellv(cell, tile, settings.flipx, settings.flipy, settings.transpose)
	else:
		set_cellv(cell, tile)

func get_dir_at_cell(cell:Vector2):
	var xflip = is_cell_x_flipped(int(cell.x), int(cell.y))
	var yflip = is_cell_y_flipped(int(cell.x), int(cell.y))
	var transpose = is_cell_transposed(int(cell.x), int(cell.y))
	var dir = Directions.get_tile_dir(xflip, yflip, transpose)
	return dir
	

# --------------------------------------------------------------------------------------------------

func _spawn_submap():
	submap = get_script().new()
	submap.parentmap = self
	submap.copy_tilemap_settings_from(self)
	submap.name = name + "+1"
	add_child(submap)
	submap.set_owner(get_tree().get_edited_scene_root())
	self.set_display_folded(true)

func _pull_tile_up_one_submap(cell):
	var tile = get_tile_at_cell(cell)
	if tile == -1:
		return -1
	
	if submap != null:
		var subtile = submap._pull_tile_up_one_submap(cell)
		set_tile_at_cell(subtile, cell)
	else:
		set_tile_at_cell(-1, cell)
	return tile

# --------------------------------------------------------------------------------------------------

func _ready():
	if get_child_count() > 0:
		submap = get_child(0)
		submap.parentmap = self

func copy_tilemap_settings_from(layer):
	tile_set = layer.tile_set
	cell_size = layer.cell_size

func get_root_map():
	if parentmap != null:
		return parentmap.get_root_map()
	else:
		return self
