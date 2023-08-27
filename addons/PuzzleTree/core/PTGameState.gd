extends RefCounted

class_name PTGameState

var current_level_id = -1
var ptproject: PuzzleTreeProject = null

var context:Dictionary = {}
var layers: PTLayers

var undo_stack = []
var redo_stack = []
signal state_loaded

# --------------------------------------------------------------------------------------------------

func load_level(id:int, initial_context = {}):
	current_level_id = id
	
	if ptproject == null:
		return
	
	context = initial_context
	undo_stack.clear()
	redo_stack.clear()
	layers.clear_layers()
	
	match ptproject.world_layout:
		"world":
			# load all levels
			var mincorner = Vector2i(1000000,1000000)
			var maxcorner = -Vector2i(1000000,1000000)
			
			for def in ptproject.levels:
				mincorner = Vector2i(min(mincorner.x, def.offsetX), min(mincorner.y, def.offsetY))
				maxcorner = Vector2i(max(maxcorner.x, def.offsetX+def.width), max(maxcorner.y, def.offsetY+def.height))
				layers.load_level_layers(def)
			
			context._level_width = (maxcorner.x - mincorner.x)
			context._level_height = (maxcorner.y - mincorner.y)
			
		"series":
			var def = ptproject.levels[id]
			layers.load_level_layers(def)
			
			context._level_width = def.width
			context._level_height = def.height

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

func clone_context(context_obj):
	var context_data = {}
	for k in context_obj:
		if typeof(context_obj[k]) == TYPE_ARRAY:
			context_data[k] = context_obj[k].duplicate()
		elif typeof(context_obj[k]) == TYPE_DICTIONARY:
			context_data[k] = context_obj[k].duplicate()
		else:
			context_data[k] = context_obj[k]
			
	context_data.frame.key = null
	context_data.frame.again = false
	return context_data

# --------------------------------------------------------------------------------------------------

func initialize(ptLayers: PTLayers):
	layers = ptLayers
	if layers != null:
		ptproject = layers.ptproject
