extends Node2D
class_name PTLayers, "../icons/PTLayers.png"

var ldtk_project_data = null

var tilesets_by_uid = {}

# --------------------------------------------------------------------------------------------------

func get_tilemaps():
	var tilemaps = {}
	var to_check = get_parent().get_children()
	while(to_check.size() > 0):
		var check = to_check.pop_back()
		if check is TileMap:
			tilemaps[check.get_path()] = check
		to_check.append_array(check.get_children())
	return tilemaps

func get_bounds():
	var mincell = Vector2(0,0)
	var maxcell = Vector2(0,0)
	var tilemaps = get_tilemaps()
	for map in tilemaps:
		for cell in map.get_used_cells():
			if mincell == null:
				mincell = cell
			else:
				mincell.x = min(mincell.x, cell.x)
				mincell.y = min(mincell.y, cell.y)
			if maxcell == null:
				maxcell = cell
			else:
				maxcell.x = max(maxcell.x, cell.x)
				maxcell.y = max(maxcell.y, cell.y)
			
	return Rect2(mincell, maxcell-mincell+Vector2(1,1))

func get_entity_layers():
	var entities = []
	for child in get_children():
		if child is PTEntities:
			entities.push_back(child)
	return entities

# --------------------------------------------------------------------------------------------------

func serialize_tilemaps():
	var tilemaps = get_tilemaps()
	
	var serialized_data = {}
	for map in tilemaps.values():
		var map_data = {}
		for cell in map.get_used_cells():
			var tile = map.get_cellv(cell)
			var autotile = map.get_cell_autotile_coord(cell.x, cell.y)
			var transpose = map.is_cell_transposed(cell.x,cell.y)
			var flipx = map.is_cell_x_flipped(cell.x, cell.y)
			var flipy = map.is_cell_y_flipped(cell.x, cell.y)
			map_data[cell] = [tile, autotile, transpose, flipx, flipy]
		serialized_data[map.get_path()] = map_data
	
	for entities in get_entity_layers():
		serialized_data[entities.get_path()] = entities.serialize()
	
	return serialized_data

func deserialize_tilemaps(serialized_data):
	var tilemaps = get_tilemaps()
	
	for key in tilemaps.keys():
		var map = tilemaps[key]
		map.clear()
		if serialized_data.has(key):
			var map_data = serialized_data[key]
			for cell in map_data.keys():
				var entry = map_data[cell]
				var tile = entry[0]
				var autotile = entry[1]
				var transpose = entry[2]
				var flipx = entry[3]
				var flipy = entry[4]
				map.set_cellv(cell,tile,flipx, flipy, transpose, autotile)
	
	for entities in get_entity_layers():
		entities.deserialize(serialized_data[entities.get_path()])

# --------------------------------------------------------------------------------------------------

func clear_layers():
	for layer in get_children():
		layer.clear_layer()

func load_level_layers(level_def):
	
	var offsetX = 0
	var offsetY = 0
	if level_def.worldX != -1:
		offsetX = level_def.worldX
	if level_def.worldY != -1:
		offsetY = level_def.worldY
	
	for layer in level_def.layerInstances:
		var layer_def = get_layer_def(layer.layerDefUid)
		if layer_def.type == "Entities":
			var layer_node = get_node("%" + layer.__identifier) as PTEntities
			layer_node.load_level(layer, level_def)
			continue
		else:
			var layer_node = get_node("%" + layer.__identifier) as PTTiles
			if layer.has("gridTiles"):
				for tile in layer.gridTiles:
					var cell = Vector2((tile.px[0] + offsetX)/layer_def.gridSize, (tile.px[1] + offsetY)/layer_def.gridSize)
					layer_node.stack_tile_at_cell(tile.t, cell)
			if layer.has("autoLayerTiles"):
				for tile in layer.autoLayerTiles:
					var cell = Vector2((tile.px[0] + offsetX)/layer_def.gridSize, (tile.px[1] + offsetY)/layer_def.gridSize)
					layer_node.stack_tile_at_cell(tile.t, cell)

func get_layer_def(uid):
	for layer in ldtk_project_data.defs.layers:
		if layer.uid == uid:
			return layer
	return null

# --------------------------------------------------------------------------------------------------

func set_ldtk_project(pldtk_project):
	ldtk_project_data = pldtk_project
	if Engine.editor_hint:
		var path = ldtk_project_data.path
		var rel_base = path.substr(0,path.find_last("/")+1)
		parse_tilesets(rel_base)
		parse_layers()

func parse_tilesets(ldtk_project_location):
	tilesets_by_uid.clear()
	
	for tileset_def in ldtk_project_data.defs.tilesets:
		var texture = load(ldtk_project_location + tileset_def.relPath)
		
		var ts = TileSet.new()
		var tile_y_count = tileset_def.pxHei/tileset_def.tileGridSize
		var tile_x_count = tileset_def.pxWid/tileset_def.tileGridSize
		for y in range(tile_y_count):
			for x in range(tile_x_count):
				var id = y*tile_x_count + x
				ts.create_tile(id)
				ts.tile_set_texture(id, texture)
				ts.tile_set_region(id, Rect2(Vector2(x*tileset_def.tileGridSize, y*tileset_def.tileGridSize), Vector2(tileset_def.tileGridSize, tileset_def.tileGridSize)))
		
		tilesets_by_uid[tileset_def.uid] = ts

func parse_layers():
	for layer in get_children():
		remove_child(layer)
	
	for x in ldtk_project_data.defs.layers.size():
		var layer_def = ldtk_project_data.defs.layers[-x-1]
		if layer_def.type == "Entities":
			create_entities_layer(layer_def)
		else:
			create_layer(layer_def)

func create_layer(layer_def):
	var new_layer = PTTiles.new()
	new_layer.name = layer_def.identifier
	new_layer.cell_size = Vector2(layer_def.gridSize, layer_def.gridSize)
	new_layer.unique_name_in_owner = true
	new_layer.tile_set = tilesets_by_uid[layer_def.tilesetDefUid]
	new_layer.cell_custom_transform = Transform2D.IDENTITY
	add_child(new_layer)
	new_layer.set_owner(get_tree().get_edited_scene_root())

func create_entities_layer(layer_def):
	var new_layer = PTEntities.new()
	new_layer.name = layer_def.identifier
	new_layer.unique_name_in_owner = true
	add_child(new_layer)
	new_layer.set_owner(get_tree().get_edited_scene_root())


