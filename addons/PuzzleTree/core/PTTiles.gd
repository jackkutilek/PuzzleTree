@icon("../icons/PTTiles.png")

extends TileMap

class_name PTTiles

var submap
var parentmap

# --------------------------------------------------------------------------------------------------

func tile_to_atlas(tile:int)->Vector2i:
	if tile == -1:
		return Vector2i(-1,-1)
	var source = tile_set.get_source(0)
	var tiles_width = source.texture.get_width()/tile_set.tile_size.x
	var tiles_height = source.texture.get_height()/tile_set.tile_size.y
	var x = tile%tiles_width
	var y = int(tile / tiles_width)
	return Vector2i(x,y)

func atlas_to_tile(atlas_coords: Vector2i):
	if atlas_coords == Vector2i(-1,-1):
		return -1
	var source = tile_set.get_source(0) as TileSetAtlasSource
	var tiles_width = source.texture.get_width()/tile_set.tile_size.x
	var tiles_height = source.texture.get_height()/tile_set.tile_size.y
	return atlas_coords.y * tiles_width + atlas_coords.x

# --------------------------------------------------------------------------------------------------

func stack_tile_at_cell(tile, cell: Vector2i, dir:String = "any"):
	if any_tile_at_cell(cell):
		if submap == null:
			_spawn_submap()
		submap.stack_tile_at_cell(tile, cell, dir)
	else:
		set_tile_at_cell(tile, cell, dir)

func remove_tile_from_cell(tile: int, cell:Vector2i, dir:String = "any"):
	var tile_match = get_tile_at_cell(cell) == tile
	var dir_match = dir == "any" or get_dir_at_cell(cell) == dir
	if tile_match and dir_match:
		set_tile_at_cell(-1, cell)
		if submap != null:
			var subtile = -1
			var subtile_dir = submap.get_dir_at_cell(cell)
			subtile = submap._pull_tile_up_one_submap(cell)
			if subtile == -1:
				subtile_dir = "any"
			set_tile_at_cell(subtile, cell, subtile_dir)
	else:
		if submap != null:
			submap.remove_tile_from_cell(tile, cell, dir)
		else:
			if logger.log_level > 2:
				print("trying to remove tile from a tilemap that doesn't have it")

func replace_tile_at_cell(replace, with, cell, replace_dir="any", with_dir="any"):
	remove_tile_from_cell(replace, cell, replace_dir)
	stack_tile_at_cell(with, cell, with_dir)

func clear_cell(cell:Vector2i):
	_changed_cells[cell] = -1
	set_tile_at_cell(-1, cell)
	if submap != null:
		submap.clear_cell(cell)

func clear_map():
	clear()
	if submap != null:
		submap.clear_map()

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
		var alt_id = get_cell_alternative_tile(0, cell)
		var dir = Directions.ALL_DIRS[alt_id]
		return dir
	if submap != null:
		return submap.get_tile_dir_at_cell(tile, cell)
	return null

func is_empty_at_cell(cell:Vector2i):
	if get_tile_at_cell(cell) != -1:
		return false
	if submap != null and not submap.is_empty_at_cell(cell):
		return false
	return true

func has_tile_at_cell(tile: int, cell:Vector2i, dir:String = "any"):
	if get_tile_at_cell(cell) == tile:
		if dir == "any":
			return true
		var tile_dir = get_dir_at_cell(cell)
		if tile_dir == dir:
			return true
	if submap != null and submap.has_tile_at_cell(tile, cell, dir):
		return true
	return false

func any_tile_at_cell(cell:Vector2i):
	return not is_empty_at_cell(cell)

func get_cells_with_tile(tile: int):
	var atlas = tile_to_atlas(tile)
	var cells = get_used_cells_by_id(0, 0, atlas)
	if submap != null:
		var subcells = submap.get_cells_with_tile(tile)
		for subcell in subcells:
			if not cells.has(subcell):
				cells.append(subcell)
	return cells

var _changed_cells: Dictionary

func get_changed_cells():
	return _changed_cells.keys()
	
func get_all_used_cells():
	return get_used_cells(0)
	
# --------------------------------------------------------------------------------------------------

func get_tile_at_cell(cell:Vector2i):
	var atlas_id = get_cell_atlas_coords(0, cell)
	var tile = atlas_to_tile(atlas_id)
	return tile

func set_tile_at_cell(tile:int, cell:Vector2i, dir:String = "any"):
	_changed_cells[cell] = tile
	var atlas_id = tile_to_atlas(tile)
	if dir != "any":
		var dir_index = Directions.ALL_DIRS.find(dir)
		set_cell(0, cell, 0, atlas_id, dir_index)
	else:
		set_cell(0, cell, 0, atlas_id)

func get_dir_at_cell(cell:Vector2i):
	var alt_id = get_cell_alternative_tile(0, cell)
	return Directions.ALL_DIRS[alt_id]

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
			subtile_dir = "any"
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
