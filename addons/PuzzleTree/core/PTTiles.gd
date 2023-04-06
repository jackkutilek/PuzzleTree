@icon("../icons/PTTiles.png")

extends Node2D

class_name PTTiles

@export var texture: Texture2D
@export var tile_size: Vector2i = Vector2i(5,5)

var tile_map: TileMap
var layer_count = 1

func is_layer_valid(layer:int)->bool:
	return layer < layer_count;

# --------------------------------------------------------------------------------------------------

func stack_tile_at_cell(tile, cell: Vector2i, dir:String = "any"):
	_stack_tile_at_cell(tile, cell, dir, 0)
func _stack_tile_at_cell(tile:int, cell:Vector2i, dir:String, layer:int):
	if _is_cell_taken(cell, layer):
		_stack_tile_at_cell(tile, cell, dir, layer+1)
	else:
		if not is_layer_valid(layer):
			tile_map.add_layer(layer)
			layer_count += 1
		_set_tile_at_cell(tile, cell, dir, layer)

func set_tile_at_cell(tile:int, cell:Vector2i, dir:String = "any"):
	clear_cell(cell)
	stack_tile_at_cell(tile, cell, dir)

func remove_tile_from_cell(tile: int, cell:Vector2i, dir:String = "any"):
	_remove_tile_from_cell(tile, cell, dir, 0)
func _remove_tile_from_cell(tile:int, cell:Vector2i, dir:String, layer:int):
	if not is_layer_valid(layer):
		if logger.log_level > 2:
			print("trying to remove tile from a tilemap that doesn't have it")
		return
	
	var tile_match = _get_tile_at_cell(cell, layer) == tile
	var dir_match = dir == "any" or _get_dir_at_cell(cell, layer) == dir
	if tile_match and dir_match:
		_set_tile_at_cell(-1, cell, "any", layer)
		_settle_cell_stack(cell, layer)
	else:
		_remove_tile_from_cell(tile, cell, dir, layer+1)

func replace_tile_at_cell(replace, with, cell, replace_dir="any", with_dir="any"):
	remove_tile_from_cell(replace, cell, replace_dir)
	stack_tile_at_cell(with, cell, with_dir)

func clear_cell(cell:Vector2i):
	if _is_cell_taken(cell, 0):
		_changed_cells[cell] = -1
		var layer = 0
		while is_layer_valid(layer):
			_clear_cell(cell, layer)
			layer += 1

func clear_map():
	tile_map.clear()

# --------------------------------------------------------------------------------------------------

func get_tiles_at_cell(cell:Vector2i)->Array[int]:
	var tiles:Array[int] = []
	_get_tiles_at_cell_recursive(cell, tiles, 0)
	return tiles
func _get_tiles_at_cell_recursive(cell:Vector2i, tiles:Array, layer:int)->Array[int]:
	var tile = _get_tile_at_cell(cell, layer)
	if tile != -1:
		tiles.append(tile)
		_get_tiles_at_cell_recursive(cell, tiles, layer+1)
	return tiles

func get_tile_dir_at_cell(tile:int, cell:Vector2i):
	var layer = 0
	while is_layer_valid(layer):
		if _get_tile_at_cell(cell, layer) == tile:
			return _get_dir_at_cell(cell, layer)
		layer += 1
	return null

func is_empty_at_cell(cell:Vector2i):
	return not _is_cell_taken(cell, 0)

func any_tile_at_cell(cell:Vector2i):
	return _is_cell_taken(cell, 0)

func has_tile_at_cell(tile: int, cell:Vector2i, dir:String = "any"):
	var layer = 0
	while is_layer_valid(layer):
		if _get_tile_at_cell(cell, layer) == tile:
			if dir == "any":
				return true
			var tile_dir = _get_dir_at_cell(cell, layer)
			if tile_dir == dir:
				return true
		layer += 1
	return false

func get_cells_with_tile(tile: int):
	var atlas = _tile_to_atlas(tile)
	var cells: Array[Vector2i] = []
	_get_cells_with_tile_recursive(atlas, 0, cells)
	return cells
func _get_cells_with_tile_recursive(atlas: Vector2i, layer:int, cells: Array[Vector2i]):
	var layer_cells = tile_map.get_used_cells_by_id(layer, 0, atlas)
	for layer_cell in layer_cells:
		if not cells.has(layer_cell):
			cells.push_back(layer_cell)
	if is_layer_valid(layer+1):
		_get_cells_with_tile_recursive(atlas, layer+1, cells)

var _changed_cells: Dictionary

func get_changed_cells():
	return _changed_cells.keys()
	
func get_all_used_cells():
	return tile_map.get_used_cells(0)

func local_to_map(local:Vector2)->Vector2i:
	return tile_map.local_to_map(local)

# --------------------------------------------------------------------------------------------------

func reset_changed_cells():
	_changed_cells.clear()

# --------------------------------------------------------------------------------------------------

func _is_cell_taken(cell:Vector2i, layer:int)->bool:
	return _get_tile_at_cell(cell, layer) != -1

func _get_tile_at_cell(cell:Vector2i, layer:int)->int:
	if not is_layer_valid(layer):
		return -1
	var atlas_id = tile_map.get_cell_atlas_coords(layer, cell)
	var tile = _atlas_to_tile(atlas_id)
	return tile

func _get_dir_at_cell(cell:Vector2i, layer:int)->String:
	var alt_id = tile_map.get_cell_alternative_tile(layer, cell)
	return Directions.ALL_DIRS[alt_id]

func _set_tile_at_cell(tile:int, cell:Vector2i, dir:String, layer:int)->void:
	assert(is_layer_valid(layer))
	_changed_cells[cell] = tile
	var atlas_id = _tile_to_atlas(tile)
	if dir != "any":
		var dir_index = Directions.ALL_DIRS.find(dir)
		tile_map.set_cell(layer, cell, 0, atlas_id, dir_index)
	else:
		tile_map.set_cell(layer, cell, 0, atlas_id)

func _clear_cell(cell:Vector2i, layer:int):
	_set_tile_at_cell(-1, cell, "any", layer)

func _settle_cell_stack(cell:Vector2i, layer:int):
	if not is_layer_valid(layer):
		return
	if not _is_cell_taken(cell, layer):
		if _is_cell_taken(cell, layer+1):
			var next_tile = _get_tile_at_cell(cell, layer+1)
			var next_dir = _get_dir_at_cell(cell, layer+1)
			_set_tile_at_cell(next_tile, cell, next_dir, layer)
			_set_tile_at_cell(-1, cell, "any", layer+1)
	_settle_cell_stack(cell, layer+1)
# --------------------------------------------------------------------------------------------------

func _tile_to_atlas(tile:int)->Vector2i:
	if tile == -1:
		return Vector2i(-1,-1)
	var source = tile_map.tile_set.get_source(0)
	var tiles_width = source.texture.get_width()/tile_size.x
	var tiles_height = source.texture.get_height()/tile_size.y
	var x = tile%tiles_width
	var y = int(tile / tiles_width)
	return Vector2i(x,y)

func _atlas_to_tile(atlas_coords: Vector2i):
	if atlas_coords == Vector2i(-1,-1):
		return -1
	var source = tile_map.tile_set.get_source(0) as TileSetAtlasSource
	var tiles_width = source.texture.get_width()/tile_size.x
	var tiles_height = source.texture.get_height()/tile_size.y
	return atlas_coords.y * tiles_width + atlas_coords.x
# --------------------------------------------------------------------------------------------------

func copy_tilemap_settings_from(layer):
	texture = layer.texture
	tile_size = layer.tile_size
	_update_scale()

func get_stack_at_cell(cell: Vector2i):
	return _get_stack_at_cell(cell, 0, "")
func _get_stack_at_cell(cell: Vector2i, layer:int, stack_string: String):
	if not is_layer_valid(layer):
		return stack_string
	var tile = _get_tile_at_cell(cell, layer)
	var dir = _get_dir_at_cell(cell, layer)
	if tile != -1:
		var new_string = stack_string + String.num(tile) + "." + dir + " "
		return _get_stack_at_cell(cell, layer+1, new_string)
	else:
		var new_string = stack_string + ". "
		return _get_stack_at_cell(cell, layer+1, new_string)

# --------------------------------------------------------------------------------------------------

func set_tileset(texture:Texture2D, tile_size: Vector2i):
	self.texture = texture
	self.tile_size = tile_size
	if tile_map == null:
		_init_tilemap()
	if Engine.is_editor_hint():
		# need to use this static method since nonstatic access doesn't work in editor
		tile_map.tile_set = PTTileSets.create_tileset(texture, tile_size)
	else:
		tile_map.tile_set = PTTileSets.get_tile_set(texture, tile_size)

func _ready():
	if has_node("tilemap"):
		tile_map = get_node("tilemap") as TileMap
	if tile_map == null:
		_init_tilemap()
		set_tileset(texture, tile_size)
	
	_update_scale()

func _init_tilemap():
	if texture != null:
		tile_map = TileMap.new()
		tile_map.name = "tilemap"
		add_child(tile_map)

func _update_scale():
	scale = _get_relative_scale()

func _get_relative_scale()->Vector2:
	var game = _get_PTGame()
	if game == null:
		return Vector2(1,1)
	var sample_tile_layer = game.get_node("PTLayers").get_child(0) as PTTiles
	var sample_size = sample_tile_layer.tile_size
	var scale = Vector2(float(sample_size.x)/tile_size.x, float(sample_size.y)/tile_size.y)
	return scale

func _get_PTGame()->PTGame:
	var parent = get_parent()
	while(parent != null):
		if parent is PTGame:
			return parent
		parent = parent.get_parent()
	return null
