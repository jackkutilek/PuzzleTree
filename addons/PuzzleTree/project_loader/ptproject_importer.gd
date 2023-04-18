@tool
extends EditorImportPlugin


func _get_importer_name():
	return "puzzletree.project"

func _get_visible_name():
	return "PuzzleTree Project"

func _get_recognized_extensions():
	return ["ldtk", "ptp"]

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
			project = _import_ptp(file_text, rel_base)
	assert(project != null, "invalid file type passed to PTP import")
	
	var filename = save_path + "." + _get_save_extension()
	var result = ResourceSaver.save(project, filename)
	
	return result

func _import_ldtk(file_text:String, relative_base:String)->PuzzleTreeProject:
	var json_conv = JSON.new()
	json_conv.parse(file_text)
	var data = json_conv.get_data()
	
	var project = PuzzleTreeProject.new()
	project.suspend_emit = true
	
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
	
	project.suspend_emit = false
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

func _import_ptp(file_text:String, relative_base:String)->PuzzleTreeProject:
	var project = PuzzleTreeProject.new()
	project.suspend_emit = true
	
	var sections = parse_sections(file_text)
	
	assert(sections.has('TILESET'), "ptp file must have TILESET section")
	var tileset = parse_tileset(sections['TILESET'])
	
	assert(sections.has('TILES'), "ptp file must have TILES section")
	var tiles = parse_tiles(sections['TILES'])
	
	assert(sections.has('LAYERS'), "ptp file must have LAYERS section")
	var layers = parse_layers(sections['LAYERS'])
	
	assert(sections.has('LEGEND'), "ptp file must have LEGEND section")
	var legend = parse_legend(sections['LEGEND'], layers, tiles)
	
	assert(sections.has('LEVELS'), "ptp file must have LEVELS section")
	var levels = parse_levels(sections['LEVELS'])
	
	
	project.base_grid_size = tileset.tile_size
	project.world_layout = "series"
	
	project.grid_layers = [] as Array[Dictionary]
	for layer_def in layers:
		var layer = {}
		layer.type = "Tiles"
		layer.identifier = layer_def.name
		layer.tile_size = tileset.tile_size
		layer.tile_spacing = tileset.tile_spacing
		layer.padding = tileset.padding
		layer.texture = relative_base + tileset.texture
		project.grid_layers.push_back(layer)
	
	project.levels = [] as Array[Dictionary]
	for level_def in levels:
		var level = {}
		level.offsetX = level_def.offsetX
		level.offsetY = level_def.offsetY
		level.width = level_def.width
		level.height = level_def.height
		level.layers = {}
		
		for layer_def in layers:
			if layer_def.default.size() > 0:
				if not level.layers.has(layer_def.name):
					level.layers[layer_def.name] = {identifier=layer_def.name, used_cells={}}
				for y in range(level.height):
					for x in range(level.width):
						var cell = Vector2i(x,y)
						if not level.layers[layer_def.name].used_cells.has(cell):
							level.layers[layer_def.name].used_cells[cell] = []
						for tile in layer_def.default:
							level.layers[layer_def.name].used_cells[cell].push_back(tiles[tile])
		
		for y in range(level_def.lines.size()):
			var line = level_def.lines[y]
			for x in range(line.length()):
				var cell = Vector2i(x,y)
				var cell_token = line[x]
				if cell_token == ' ':
					continue
				var layer_defs = legend.get(cell_token)
				for layer_def in layer_defs:
					if not level.layers.has(layer_def.layer):
						level.layers[layer_def.layer] = {identifier=layer_def.layer, used_cells={}}
					for tile in layer_def.tiles:
						if not level.layers[layer_def.layer].used_cells.has(cell):
							level.layers[layer_def.layer].used_cells[cell] = []
						level.layers[layer_def.layer].used_cells[cell].push_back(tiles[tile])

		project.levels.push_back(level)
	
	project.suspend_emit = false
	return project
	
func parse_sections(file_text:String)->Dictionary:
	var lines = file_text.split('\n')
	var sections = {}
	
	const SECTION_NAMES = ['TILESET', 'TILES', 'LAYERS', 'LEGEND', 'LEVELS']
	
	var section_indices = []
	var index = 0
	while index < lines.size():
		var line = lines[index]
		if SECTION_NAMES.has(line):
			var name = line
			var section_lines = []
			index += 1
			while index < lines.size() and not SECTION_NAMES.has(lines[index]):
				section_lines.push_back(lines[index])
				index += 1
				
			sections[name] = section_lines
	return sections

func parse_tileset(lines: Array):
	assert(lines.size() >= 2, "tileset section must have two lines")
	var texture = lines[0]
	var size = lines[1]
	var coords = size.split(' ')
	assert(coords.size() == 2, "expected two coordinates for tile set in tileset: " + size)
	var tile_size = Vector2i(int(coords[0]), int(coords[1]))
	return {texture=texture, tile_size=tile_size, tile_spacing=0, padding=0}
	
func parse_tiles(lines: Array):
	var tiles = {}
	for line in lines:
		if line == '':
			continue
		var index = tiles.size()
		tiles[line] = index
	return tiles

func parse_layers(lines: Array):
	var layers = []
	for line in lines:
		if line == '':
			continue
		var layer = {}
		var tokens = line.split('|')
		assert(tokens.size() <= 2, "layer definition can only have one | character: " + line)
		layer.name = tokens[0]
		layer.default = []
		if tokens.size() > 1:
			layer.default.push_back(tokens[1])
		layers.push_back(layer)
	return layers

func parse_legend(lines: Array, layers: Array, tile_defs: Dictionary):
	var legend = {}
	for line in lines:
		if line == '':
			continue
		var tokens = line.split('=')
		assert(tokens.size() == 2, "LEGEND: cell definition must have one = character: " + line)
		var key = tokens[0].lstrip(' ').rstrip(' ')
		var rhs = tokens[1]
		var layer_tokens = rhs.split(']')
		assert(layer_tokens.size() >= 2, "LEGEND: cell description must have at least one ] character: " + rhs)
		var layer_defs = []
		for layer_token in layer_tokens:
			layer_token = layer_token.lstrip(' ').rstrip(' ')
			if layer_token == '':
				continue
			var cell_tokens = layer_token.split('[')
			assert(cell_tokens.size() == 2, "LEGEND: layer description must have one [ character: " + layer_token)
			var layer = cell_tokens[0].lstrip(' ').rstrip(' ')
			assert(has_layer(layers, layer), "LEGEND: invalid layer name " + layer)
			var tiles_string = cell_tokens[1].lstrip(' ').rstrip(' ')
			var tiles = tiles_string.split(' ')
			for tile in tiles:
				assert(tile_defs.has(tile), "LEGEND: invalid tile specified (" + key + ") at " + rhs)
			layer_defs.push_back({layer=layer, tiles=tiles})
		legend[key] = layer_defs
	return legend
	
	
func has_layer(layers:Array, name:String):
	for layer in layers:
		if layer.name == name:
			return true
	return false

func parse_levels(lines: Array):
	var levels = []
	
	var level
	var index = 0
	while index < lines.size():
		level = {}
		level.offsetX = 0
		level.offsetY = 0
		
		var level_lines = []
		while lines[index] == '':
			index += 1
		level.name = lines[index]
		index += 1
		if index >= lines.size():
			break
		var width = 0
		while lines[index] != '':
			var line = lines[index]
			width = max(line.length(), width)
			level_lines.push_back(line)
			index += 1
			if index >= lines.size():
				break
		level.lines = level_lines
		level.width = width
		level.height = level.lines.size()
		levels.push_back(level)
	
	return levels
