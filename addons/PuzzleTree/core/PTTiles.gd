@icon("../icons/PTTiles.png")

extends PTTileMap

class_name PTTiles

var submap
var parentmap

# --------------------------------------------------------------------------------------------------

func stack_tile_at_cell(tile, cell: Vector2i, dir = null):
	if any_tile_at_cell(cell):
		if submap == null:
			_spawn_submap()
		submap.stack_tile_at_cell(tile, cell, dir)
	else:
		set_tile_at_cell(tile, cell, dir)

func remove_tile_from_cell(tile, cell:Vector2i, dir = null):
	var tile_match = get_cellv(cell) == tile
	var dir_match = dir == null or get_dir_at_cell(cell) == dir
	if tile_match and dir_match:
		set_tile_at_cell(-1, cell)
		if submap != null:
			var subtile = -1
			var subtile_dir = submap.get_dir_at_cell(cell)
			subtile = submap._pull_tile_up_one_submap(cell)
			if subtile == -1:
				subtile_dir = null
			set_tile_at_cell(subtile, cell, subtile_dir)
	else:
		if submap != null:
			submap.remove_tile_from_cell(tile, cell, dir)
		else:
			if logger.log_level > 2:
				print("trying to remove tile from a tilemap that doesn't have it")

func replace_tile_at_cell(replace, with, cell, replace_dir=null, with_dir=null):
	remove_tile_from_cell(replace, cell, replace_dir)
	stack_tile_at_cell(with, cell, with_dir)

func clear_cell(cell:Vector2i):
	_changed_cells[cell] = -1
	set_tile_at_cell(-1, cell)
	if submap != null:
		submap.clear_cell(cell)

func clear_layer():
	clear()
	if submap != null:
		submap.clear_layer()

# --------------------------------------------------------------------------------------------------

func get_tiles_at_cell(cell:Vector2i):
	var tiles = []
	get_tiles_at_cell_recursive(cell, tiles)
	return tiles
func get_tiles_at_cell_recursive(cell:Vector2i, tiles:Array):
	var tile = get_tile_at_cell(cell)
	if tile != -1:
		tiles.append(tile)
		if submap != null:
			submap.get_tiles_at_cell_recursive(cell, tiles)
	return tiles

func get_tile_dir_at_cell(tile, cell:Vector2i):
	if get_tile_at_cell(cell) == tile:
		var xflip = is_cell_x_flipped(int(cell.x), int(cell.y))
		var yflip = is_cell_y_flipped(int(cell.x), int(cell.y))
		var transpose = is_cell_transposed(int(cell.x), int(cell.y))
		var dir = Directions.get_tile_dir(xflip, yflip, transpose)
		return dir
	if submap != null:
		return submap.get_tile_dir_at_cell(tile, cell)
	return null

func is_empty_at_cell(cell:Vector2i):
	if get_cellv(cell) != -1:
		return false
	if submap != null and not submap.is_empty_at_cell(cell):
		return false
	return true

func has_tile_at_cell(tile, cell:Vector2i, dir = null):
	if get_cellv(cell) == tile:
		if dir == null:
			return true
		var xflip = is_cell_x_flipped(int(cell.x), int(cell.y))
		var yflip = is_cell_y_flipped(int(cell.x), int(cell.y))
		var transpose = is_cell_transposed(int(cell.x), int(cell.y))
		var tile_dir = Directions.get_tile_dir(xflip, yflip, transpose)
		if tile_dir == dir:
			return true
	if submap != null and submap.has_tile_at_cell(tile, cell, dir):
		return true
	return false

func any_tile_at_cell(cell:Vector2i):
	return not is_empty_at_cell(cell)

func get_cells_with_tile(tile):
	var cells = get_used_cells(tile)
	if submap != null:
		var subcells = submap.get_cells_with_tile(tile)
		for subcell in subcells:
			if not cells.has(subcell):
				cells.append(subcell)
	return cells

var _changed_cells: Dictionary

func get_changed_cells():
	return _changed_cells.keys()
	
# --------------------------------------------------------------------------------------------------

func get_tile_at_cell(cell:Vector2i):
	return get_cellv(cell)

func set_tile_at_cell(tile, cell:Vector2i, dir = null):
	_changed_cells[cell] = tile
	if dir != null:
		var settings = Directions.get_tile_settings(dir)
		set_cellv(cell, tile, settings.flipx, settings.flipy, settings.transpose)
	else:
		set_cellv(cell, tile)

func get_dir_at_cell(cell:Vector2i):
	var xflip = is_cell_x_flipped(int(cell.x), int(cell.y))
	var yflip = is_cell_y_flipped(int(cell.x), int(cell.y))
	var transpose = is_cell_transposed(int(cell.x), int(cell.y))
	var dir = Directions.get_tile_dir(xflip, yflip, transpose)
	return dir

func reset_changed_cells():
	_changed_cells.clear()

# --------------------------------------------------------------------------------------------------

func _spawn_submap():
	submap = get_script().new()
	submap.parentmap = self
	submap.copy_tilemap_settings_from(self)
	submap.name = name + "+1"
	add_child(submap)
	if get_tree() != null:
		submap.set_owner(get_tree().get_edited_scene_root())
	self.set_display_folded(true)

func _pull_tile_up_one_submap(cell):
	var tile = get_tile_at_cell(cell)
	if tile == -1:
		return -1
	
	if submap != null:
		var subtile_dir = submap.get_dir_at_cell(cell)
		var subtile = submap._pull_tile_up_one_submap(cell)
		if subtile == -1:
			subtile_dir = null
		set_tile_at_cell(subtile, cell, subtile_dir)
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

func get_stack_at_cell(cell: Vector2i):
	return _get_stack_at_cell(cell, "")
func _get_stack_at_cell(cell: Vector2i, stack_string: String):
	var tile = get_tile_at_cell(cell)
	var dir = get_dir_at_cell(cell)
	if tile != -1:
		var new_string = stack_string + String.num(tile) + "." + dir + " "
		if submap != null:
			return submap._get_stack_at_cell(cell, new_string)
		else:
			return new_string
	else:
		return stack_string + ". "
