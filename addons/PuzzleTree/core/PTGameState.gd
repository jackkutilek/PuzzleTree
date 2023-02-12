extends Reference

class_name PTGameState

var current_level_id = -1
var ldtk_project_data = null

var context:Dictionary = {}
var layers: PTLayers

var undo_stack = []
signal state_loaded

# --------------------------------------------------------------------------------------------------

func set_level(id:int):
	current_level_id = -1
	
	match ldtk_project_data.worldLayout:
		"GridVania", "Free":
			# load all levels
			undo_stack.clear()
			layers.clear_layers()
			for def in ldtk_project_data.levels:
				layers.load_level_layers(def)
			
		"LinearHorizontal", "LinearVertical":
			var def = ldtk_project_data.levels[id]
			undo_stack.clear()
			layers.clear_layers()
			layers.load_level_layers(def)
			current_level_id = id
			
			context._level_width = def.pxWid / ldtk_project_data.defaultGridSize
			context._level_height = def.pxHei / ldtk_project_data.defaultGridSize

func undo():
	if undo_stack.size() > 1:
		print("undo")
		var data = undo_stack.pop_back()
		load_state(data)
	else:
		print("undo stack is empty")
		pass
	
func reset():
	print("reset")
	save_state(gather_state())
	var data = undo_stack[0]
	load_state(data)

func set_checkpoint(data):
	undo_stack[0] = data

# --------------------------------------------------------------------------------------------------

func save_state(data):
	undo_stack.push_back(data)

func load_state(data):
	context = {}
	
	for k in data.context_data:
		context[k] = data.context_data[k]
	layers.deserialize_tilemaps(data.map_data)
	
	emit_signal("state_loaded")

# --------------------------------------------------------------------------------------------------

func state_hasnt_changed():
	return deep_equal(undo_stack.back(), gather_state())

func drop_last_state():
	undo_stack.pop_back()

# --------------------------------------------------------------------------------------------------

func gather_state():
	var map_data = layers.serialize_tilemaps()
	var context_data = clone_context(context)
	var data = {map_data = map_data, context_data = context_data}
	return data

func clone_context(context_obj):
	var context_data = {}
	for k in context_obj:
		if k == 'key' or k == "again":
			continue
		if typeof(context_obj[k]) == TYPE_ARRAY:
			context_data[k] = context_obj[k].duplicate()
		elif typeof(context_obj[k]) == TYPE_DICTIONARY:
			context_data[k] = context_obj[k].duplicate()
		else:
			context_data[k] = context_obj[k]
	return context_data

# --------------------------------------------------------------------------------------------------

func initialize(ptLayers: PTLayers):
	layers = ptLayers
	ldtk_project_data = layers.ldtk_project_data
