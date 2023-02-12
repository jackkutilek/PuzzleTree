extends Node2D

class_name PTEntities, "../icons/PTEntities.png"

export var entities := []



func clear_layer():
	entities.clear()

func load_level(layer_def, level_def):
	var tile_offset = Vector2(level_def.worldX, level_def.worldY)/layer_def.__gridSize
	
	for entity in layer_def.entityInstances:
		var new_entity = {}
		new_entity.id = entity.__identifier
		new_entity.cell = Vector2(entity.__grid[0], entity.__grid[1]) + tile_offset
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
					new_entity[field_id] = Vector2(fi.__value.cx, fi.__value.cy)
				"Array<Point>":
					new_entity[field_id] = []
					for p in fi.__value:
						new_entity[field_id].push_back(Vector2(p.cx, p.cy)+tile_offset)
			
		entities.push_back(new_entity)

func deep_clone(dict):
	if dict is int or dict is float or dict is bool or dict is String:
		return dict
	elif dict is Vector2:
		return Vector2(dict.x, dict.y)
	elif dict is Dictionary:
		var clone = {}
		for key in dict.keys():
			clone[key] = deep_clone(dict[key])
		return clone
	elif dict is Array:
		var clone = []
		for el in dict:
			clone.push_back(deep_clone(el))
		return clone
	
	assert(false)

func serialize():
	var data = []
	for entity in entities:
		data.push_back(deep_clone(entity))
	return data


func deserialize(data):
	entities.clear()
	for entity in data:
		entities.push_back(deep_clone(entity))
