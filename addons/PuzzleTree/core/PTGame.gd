@tool
@icon("../icons/PTGame.png")

extends Node2D
class_name PTGame

signal quit

@export var puzzletree_project: PuzzleTreeProject : set = _set_project
@export var reload_pt_project = false : set = _reload_project
@export var base_tile_size: Vector2i = Vector2i(5,5)
@export var starting_level: int = 0 : set = _set_starting_level
@export var clear_color: Color = Color.GRAY

@export var run_turns_on_keyup = false
@export var enable_mouse_turns = false
@export var key_repeat_interval:float = .2 : set = _set_key_repeat_interval
@export var again_interval:float = .1 : set = _set_again_interval
@export var realtime_interval:float = 0.0 : set = _set_realtime_interval
@export var log_level:int = 0 : set = _set_log_level

var is_ready = false
var engine: PTEngine
var layers: PTLayers

# --------------------------------------------------------------------------------------------------

func load_level(id:int, initial_context={}):
	engine.load_level(id, initial_context)

# --------------------------------------------------------------------------------------------------

func _set_project(value):
	if puzzletree_project == value:
		return
		
	if Engine.is_editor_hint():
		if puzzletree_project != null:
			puzzletree_project.disconnect("changed",_ptp_changed)
			
	puzzletree_project = value
	if puzzletree_project == null:
		return
	
	if Engine.is_editor_hint():
		if not puzzletree_project.is_connected("changed",_ptp_changed):
			puzzletree_project.connect("changed",_ptp_changed)
			print("#-- Watching for changes to PuzzleTree project at ", puzzletree_project.resource_path, " --#")
	
	if Engine.is_editor_hint() and is_ready:
		print("#-- PuzzleTree project set --#")
		_load_project()

func _reload_project(value):
	if Engine.is_editor_hint() and value:
		print("#-- triggered PuzzleTree project reload at ", Time.get_datetime_string_from_system(false, true) ," --#")
		_load_project()

func _ptp_changed():
	print("#-- PuzzleTree project changes detected at ", Time.get_datetime_string_from_system(false, true) ,"... reloading project --#")
	_load_project()

func _load_project():
	if not is_ready or get_tree() == null:
		print("#-- !! cannot load PuzzleTree project !! --#")
		return
	
	if puzzletree_project != null:
		var resource_path = puzzletree_project.resource_path
		print("#-- loading PuzzleTree project at ", resource_path, " --#")
	else:
		print("#-- loading game with no project --#")
	
	_initialize_layers_node()
	_initialize_engine()
	_initialize_camera_node()
	engine.switch_to_level(starting_level)

# --------------------------------------------------------------------------------------------------

func _initialize_layers_node():
	layers = PTLayers.new()
	layers.root_node = self
	layers.set_pt_project(puzzletree_project)

func _initialize_engine():
	engine = PTEngine.new()
	engine.initialize(self, layers)
	engine.connect('quit', _engine_quit)
	engine.run_turns_on_keyup = run_turns_on_keyup
	engine.enable_mouse_turns = enable_mouse_turns
	engine.again_interval = again_interval
	engine.realtime_interval = realtime_interval
	engine.key_repeat_interval = key_repeat_interval
	engine.base_tile_size = base_tile_size
	engine.switch_to_level(starting_level)

func _engine_quit():
	var connections = get_signal_connection_list('quit')
	if connections.size() > 0:
		emit_signal('quit')
	else:
		get_tree().quit()

func _initialize_camera_node():
	if Engine.is_editor_hint():
		if get_viewport().get_camera_2d() != null:
			print("#-- active camera already exists, will not create PTCamera --#")
			return
		
		for node in _get_tree_nodes():
			if node.get_class() == "Camera2D":
				print("#-- camera node already exists, will not create PTCamera --#")
				node.make_current()
				return
		
		print("#-- creating new PTCamera --#")
		var camera = PTCamera.new()
		camera.name = "PTCamera"
		if puzzletree_project != null:
			camera.tile_size = puzzletree_project.base_grid_size
		add_child(camera)
		camera.set_owner(get_tree().get_edited_scene_root())
		camera.make_current()

# --------------------------------------------------------------------------------------------------

func _set_starting_level(value):
	if puzzletree_project == null or engine == null:
		starting_level = value
		return
	
	if value >= puzzletree_project.levels.size():
		value = puzzletree_project.levels.size()-1
	if value < 0:
		value = 0
	
	if starting_level != value:
		starting_level = value
		engine.switch_to_level(starting_level)

# --------------------------------------------------------------------------------------------------

func _get_tree_nodes():
	var nodes = []
	_get_tree_nodes_recursive(self, nodes)
	return nodes

func _get_tree_nodes_recursive(node, collected_nodes):
	collected_nodes.push_back(node)
	for child in node.get_children():
		_get_tree_nodes_recursive(child, collected_nodes)

# --------------------------------------------------------------------------------------------------

func _ready():
	is_ready = true
		
	print("#-- game ready, loading project --#")
	_load_project()

func _process(delta):
	if not Engine.is_editor_hint():
		if engine != null:
			engine._process(delta)

func _draw():
	draw_rect(Rect2(-10000,-10000,100000,100000), clear_color)

func _unhandled_key_input(event):
	if not Engine.is_editor_hint():
		if engine._unhandled_key_input(event):
			get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if not Engine.is_editor_hint():
		if engine._unhandled_input(event):
			get_viewport().set_input_as_handled()
	

func _set_key_repeat_interval(value):
	key_repeat_interval = value
	if engine != null:
		engine.key_repeat_interval = value
		
func _set_again_interval(value):
	again_interval = value
	if engine != null:
		engine.again_interval = value

func _set_realtime_interval(value):
	realtime_interval = value
	if engine != null:
		engine.realtime_interval = value

func _set_log_level(value):
	log_level = value
	logger.log_level = value
