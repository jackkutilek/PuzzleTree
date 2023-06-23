@tool
extends RefCounted
class_name PTLayers

var ptproject:PuzzleTreeProject = null
var root_node: Node2D
var tilesets_by_uid = {}

# --------------------------------------------------------------------------------------------------

func get_bounds():
	var mincell = Vector2i(0,0)
	var maxcell = Vector2i(0,0)
	var tilemaps = get_tile_layers()
	for map in tilemaps.values():
		for cell in map.get_used_cells(0):
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
			
	return Rect2(mincell, maxcell-mincell+Vector2i(1,1))

func get_tile_layers()->Dictionary:
	var tilemaps = {}
	var to_check = root_node.get_children()
	while(to_check.size() > 0):
		var check = to_check.pop_back()
		if check is PTTiles:
			tilemaps[check.get_path()] = check
		to_check.append_array(check.get_children())
	return tilemaps
	
func get_entity_layers()->Dictionary:
	var entities = {}
	var to_check = root_node.get_children()
	while(to_check.size() > 0):
		var check = to_check.pop_back()
		if check is PTEntities:
			entities[check.get_path()] = check
		to_check.append_array(check.get_children())
	return entities

# --------------------------------------------------------------------------------------------------

func serialize_tilemaps():
	var tilemaps = get_tile_layers()
	var maps = tilemaps.values() as Array[PTTiles]
	var serialized_data = {}
	for map in maps:
		var map_data = {}
		for layer in range(map.layer_count):
			var layer_data = {}
			map_data[layer] = layer_data
			if map.tile_map != null:
				for cell in map.tile_map.get_used_cells(layer):
					var tile = map.tile_map.get_cell_atlas_coords(layer, cell)
					var alt = map.tile_map.get_cell_alternative_tile(layer, cell)
					layer_data[cell] = [tile, alt]
		serialized_data[map.get_path()] = map_data
	
	for entities in get_entity_layers().values():
		serialized_data[entities.get_path()] = entities.serialize()
	
	return serialized_data

func deserialize_tilemaps(serialized_data):
	var tilemaps = get_tile_layers()
	
	for key in tilemaps.keys():
		var map = tilemaps[key]
		map.tile_map.clear()
		if serialized_data.has(key):
			var map_data = serialized_data[key]
			for layer in map_data.keys():
				var layer_data = map_data[layer]
				for cell in layer_data.keys():
					var entry = layer_data[cell]
					var tile = entry[0]
					var alt = entry[1]
					map.tile_map.set_cell(layer, cell, 0, tile, alt)
	
	for entities in get_entity_layers().values():
		entities.deserialize(serialized_data[entities.get_path()])

# --------------------------------------------------------------------------------------------------

func clear_layers():
	for layer in get_tile_layers().values():
		layer.clear_map()
	for layer in get_entity_layers().values():
		layer.clear_map()

func load_level_layers(level_def):
	for layer in level_def.layers.values():
		var layer_def = get_layer_def(layer.identifier)
		if layer_def.type == "Entities":
			var layer_node = root_node.get_node("%" + layer.identifier) as PTEntities
			layer_node.entities.append_array(layer.entities)
			continue
		else:
			var layer_node = root_node.get_node("%" + layer.identifier) as PTTiles
			for cell in layer.used_cells.keys():
				var tiles = layer.used_cells[cell]
				for tile in tiles:
					layer_node.stack_tile_at_cell(tile, cell)

func get_layer_def(identifier):
	for layer in ptproject.grid_layers:
		if layer.identifier == identifier:
			return layer
	return null

# --------------------------------------------------------------------------------------------------

func set_pt_project(ptproject_):
	ptproject = ptproject_
	if ptproject != null and Engine.is_editor_hint():
		parse_layers()

func get_synced_layers():
	var layers = []
	var to_check = root_node.get_children()
	while(to_check.size() > 0):
		var check = to_check.pop_back()
		if check is PTSyncedEntities or check is PTSyncedTiles:
			layers.push_back(check)
		to_check.append_array(check.get_children())
	return layers

func parse_layers():
	var layers = get_synced_layers()
	
	for layer_def in ptproject.grid_layers:
		if layer_def.type == "Entities":
			var layer = create_entities_layer(layer_def)
			layers.erase(layer)
		else:
			var layer = create_layer(layer_def)
			layers.erase(layer)
	
	# remove layers that no longer exist in PTP
	for layer in layers:
		root_node.remove_child(layer)

func create_layer(layer_def):
	var new_layer: PTTiles
	var existing_layer = null
	if root_node.has_node("%"+layer_def.identifier):
		existing_layer = root_node.get_node("%"+layer_def.identifier)
	if existing_layer != null and existing_layer is PTTiles:
		new_layer = existing_layer as PTTiles
	else:
		new_layer = PTSyncedTiles.new()
		new_layer.name = layer_def.identifier
		new_layer.unique_name_in_owner = true
	
		root_node.add_child(new_layer)
		new_layer.set_owner(root_node.get_tree().get_edited_scene_root())
	
	var texture = load(layer_def.texture)
	var tile_size = layer_def.tile_size
	new_layer.set_tileset_from_texture(texture, tile_size)
	
	return new_layer

func create_entities_layer(layer_def):
	var new_layer: PTEntities
	var existing_layer = root_node.get_node("%"+layer_def.identifier)
	if existing_layer != null and existing_layer is PTEntities:
		new_layer = existing_layer
	else:
		new_layer = PTSyncedEntities.new()
		new_layer.name = layer_def.identifier
		new_layer.unique_name_in_owner = true
		root_node.add_child(new_layer)
		new_layer.set_owner(root_node.get_tree().get_edited_scene_root())
	return new_layer

