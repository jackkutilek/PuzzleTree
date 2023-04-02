extends RefCounted

class_name PTGameState

var current_level_id = -1
var ldtk_project_data = null

var context:Dictionary = {}
var layers: PTLayers

var undo_stack = []
var redo_stack = []
signal state_loaded

# --------------------------------------------------------------------------------------------------

func set_level(id:int):
	current_level_id = id
	
	if ldtk_project_data == null:
		return
	
	undo_stack.clear()
	redo_stack.clear()
	layers.clear_layers()
	
	match ldtk_project_data.worldLayout:
		"GridVania", "Free":
			# load all levels
			var mincorner = Vector2i(1000000,1000000)
			var maxcorner = -Vector2i(1000000,1000000)
			
			for def in ldtk_project_data.levels:
				mincorner = Vector2i(min(mincorner.x, def.worldX), min(mincorner.y, def.worldY))
				maxcorner = Vector2i(max(maxcorner.x, def.worldX+def.pxWid), max(maxcorner.y, def.worldY+def.pxHei))
				layers.load_level_layers(def)
			
			context._level_width = (maxcorner.x - mincorner.x) / ldtk_project_data.defaultGridSize
			context._level_height = (maxcorner.y - mincorner.y) / ldtk_project_data.defaultGridSize
			
		"LinearHorizontal", "LinearVertical":
			var def = ldtk_project_data.levels[id]
			layers.load_level_layers(def)
			
			context._level_width = def.pxWid / ldtk_project_data.defaultGridSize
			context._level_height = def.pxHei / ldtk_project_data.defaultGridSize

func undo():
	if undo_stack.size() > 1:
		print("undo")
		redo_stack.push_back(gather_state())
		var data = undo_stack.pop_back()
		load_state(data)
	else:
		print("undo stack is empty")
		pass

func redo():
	if redo_stack.size() > 0:
		print("redo")
		undo_stack.push_back(gather_state())
		var data = redo_stack.pop_back()
		load_state(data)
	else:
		print("redo stack is empty")
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
	redo_stack.clear()

func load_state(data):
	context = {}
	
	for k in data.context_data:
		context[k] = data.context_data[k]
	layers.deserialize_tilemaps(data.map_data)
	
	emit_signal("state_loaded")

# --------------------------------------------------------------------------------------------------

func state_hasnt_changed():
	return undo_stack.back() == gather_state()

func drop_last_state():
	undo_stack.pop_back()

# --------------------------------------------------------------------------------------------------

func gather_state():
	var map_data = layers.serialize_tilemaps()
	var context_data = clone_context(context)
	var data = {map_data = map_data, context_data = context_data}
	return data

const IGNORED_CONTEXT_KEYS = ["frame_key", "again"]
func clone_context(context_obj):
	var context_data = {}
	for k in context_obj:
		if IGNORED_CONTEXT_KEYS.has(k):
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
	if layers != null:
		ldtk_project_data = layers.ldtk_project_data
