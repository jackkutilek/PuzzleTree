@tool
extends EditorImportPlugin


func _get_importer_name():
	return "puzzletree.project"

func _get_visible_name():
	return "PuzzleTree Project"

func _get_recognized_extensions():
	return ["ldtk"]

func _get_import_options(preset, index):
	return []

func _get_import_order():
	return 0

func _get_preset_count():
	return 0

func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "PuzzleTreeProject"

func _get_priority():
	return 1.0

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]):
	var file = FileAccess.open(source_file, FileAccess.READ)
	var file_text = file.get_as_text()
	file.close()
	
	var rel_base = source_file.substr(0,source_file.rfind("/")+1)
	
	var project: PuzzleTreeProject = null
	match source_file.get_extension():
		"ldtk":
			project = _import_ldtk(file_text, rel_base)
		"ptp":
			project = _import_ptp(file_text)
	assert(project != null, "invalid file type passed to PTP import")
	
	var filename = save_path + "." + _get_save_extension()
	var result = ResourceSaver.save(project, filename)
	
	return result

func _import_ldtk(file_text:String, relative_base:String)->PuzzleTreeProject:
	var json_conv = JSON.new()
	json_conv.parse(file_text)
	var data = json_conv.get_data()
	
	var project = PuzzleTreeProject.new()
	
	var base_size = data.defaultGridSize
	project.base_grid_size = Vector2i(base_size, base_size)
	
	match data.worldLayout:
		"GridVania", "Free":
			project.world_layout = "world"
		"LinearHorizontal", "LinearVertical":
			project.world_layout = "series"
	
	var tilesets_by_uid = parse_tilesets(relative_base, data)
	
	var layers: Array[Dictionary] = []
	for layer_def in data.defs.layers:
		var layer = {}
		layer.identifier = layer_def.identifier
		if layer_def.type == "Entities":
			layer.type = "Entities"
		else:
			layer.type = "Tiles"
			var tileset = tilesets_by_uid[layer_def.tilesetDefUid]
			layer.tile_size = tileset.tile_size
			layer.tile_spacing = tileset.tile_spacing
			layer.padding = tileset.padding
			layer.texture = tileset.texture
		layers.push_back(layer)
	project.grid_layers = layers
	
	var levels: Array[Dictionary] = []
	for level_def in data.levels:
		var level = {}
		var offsetX = 0
		var offsetY = 0
		if level_def.worldX != -1:
			offsetX = level_def.worldX
		if level_def.worldY != -1:
			offsetY = level_def.worldY
		level.offsetX = offsetX
		level.offsetY = offsetY
		
		level.width = level_def.pxWid / data.defaultGridSize
		level.height = level_def.pxHei / data.defaultGridSize
		
		var level_layers = {}
		for layer in level_def.layerInstances:
			var layer_def = get_layer_def(data, layer.layerDefUid)
			
			var ptp_layer = {}
			ptp_layer.identifier = layer.__identifier
			
			level_layers[ptp_layer.identifier] = ptp_layer
			
			if layer_def.type == "Entities":
				ptp_layer.entities = get_entities(layer, level_def)
			else:
				ptp_layer.identifier = layer.__identifier
				ptp_layer.used_cells = {}
				
				if layer.has("gridTiles"):
					for tile in layer.gridTiles:
						var cell = Vector2i((tile.px[0] + offsetX)/layer_def.gridSize, (tile.px[1] + offsetY)/layer_def.gridSize)
						if not ptp_layer.used_cells.has(cell):
							ptp_layer.used_cells[cell] = []
						ptp_layer.used_cells[cell].push_back(int(tile.t))
				if layer.has("autoLayerTiles"):
					for tile in layer.autoLayerTiles:
						var cell = Vector2i((tile.px[0] + offsetX)/layer_def.gridSize, (tile.px[1] + offsetY)/layer_def.gridSize)
						if not ptp_layer.used_cells.has(cell):
							ptp_layer.used_cells[cell] = []
						ptp_layer.used_cells[cell].push_back(int(tile.t))
		level.layers = level_layers
		levels.push_back(level)
	project.levels = levels
	
	return project


func parse_tilesets(ldtk_project_location, data):
	var tilesets_by_uid = {}
	
	for tileset_def in data.defs.tilesets:
		var texture = ldtk_project_location + tileset_def.relPath
		var tile_size = Vector2i(tileset_def.tileGridSize, tileset_def.tileGridSize)
		tilesets_by_uid[tileset_def.uid] = {texture=texture, tile_size=tile_size, tile_spacing=tileset_def.spacing, padding=tileset_def.padding}
	
	return tilesets_by_uid

func get_layer_def(data, uid):
	for layer in data.defs.layers:
		if layer.uid == uid:
			return layer
	return null

func get_entities(layer_def, level_def):
	var tile_offset := Vector2i(level_def.worldX/layer_def.__gridSize, level_def.worldY/layer_def.__gridSize)
	
	var entities = []
	for entity in layer_def.entityInstances:
		var new_entity = {}
		entities.push_back(new_entity)
		new_entity.id = entity.__identifier
		new_entity.cell = Vector2i(entity.__grid[0], entity.__grid[1]) + tile_offset
		new_entity.width = entity.width/layer_def.__gridSize
		new_entity.height = entity.height/layer_def.__gridSize
		for fi in entity.fieldInstances:
			if ["cell","width","height"].has(fi.__identifier):
				print("don't name an entity field '", fi.__identifier, "' - it is a reserved name!")
				continue
			var field_id = fi.__identifier
			match fi.__type:
				"Bool", "Int", "Float", "String":
					new_entity[field_id] = fi.__value
				"Array<Bool>", "Array<Int>", "Array<Float>", "Array<String>":
					new_entity[field_id] = []
					for p in fi.__value:
						new_entity[field_id].push_back(p)
				"Point":
					new_entity[field_id] = Vector2i(fi.__value.cx, fi.__value.cy)
				"Array<Point>":
					new_entity[field_id] = []
					for p in fi.__value:
						new_entity[field_id].push_back(Vector2i(p.cx, p.cy)+tile_offset)
	
	return entities

func _import_ptp(file_text:String)->PuzzleTreeProject:
	var project = PuzzleTreeProject.new()
	return project
	
