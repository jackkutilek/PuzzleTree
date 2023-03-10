@tool
@icon("../icons/PTGame.png")

extends Node2D
class_name PTGame

@export var ldtk_project_resource: Resource : set = set_project
@export var reload_ldtk_project = false : set = reload_project

@export var starting_level: int = 0 : set = set_level
@export var clear_color: Color = Color.GRAY

@export var run_turns_on_keyup = false
@export var enable_mouse_turns = false
@export var key_repeat_interval:float = .2 : set = set_key_repeat_interval
@export var again_interval:float = .1 : set = set_again_interval
@export var log_level:int = 0 : set = set_log_level

var ldtk_project_data = null

var is_ready = false
var engine: PTEngine

# --------------------------------------------------------------------------------------------------

func set_project(value):
	if ldtk_project_resource == value:
		return
		
	if Engine.is_editor_hint():
		if ldtk_project_resource != null:
			ldtk_project_resource.disconnect("changed",ldtk_changed)
			
	ldtk_project_resource = value
	if ldtk_project_resource == null:
		return
	
	if Engine.is_editor_hint():
		if not ldtk_project_resource.is_connected("changed",ldtk_changed):
			ldtk_project_resource.connect("changed",ldtk_changed)
			print("#-- Watching for changes to LDTK project at ", ldtk_project_resource.resource_path, " --#")
	
	if Engine.is_editor_hint() and is_ready:
		print("#-- LDTK project set --#")
		load_project()

func reload_project(value):
	if Engine.is_editor_hint() and value:
		print("#-- triggered LDTK project reload --#")
		load_project()

func ldtk_changed():
	print("#-- LDTK project changes detected... reloading project --#")
	load_project()

func load_project():
	if ldtk_project_resource == null or not is_ready or get_tree() == null:
		print("#-- !! cannot load LDTK project !! --#")
		return
		
	var resource_path = ldtk_project_resource.resource_path
	print("#-- loading project at ", resource_path, " --#")
	
	ldtk_project_data = ldtk_project_resource.data
	ldtk_project_data.path = resource_path
	
	initialize_layers_node()
	initialize_engine()
	initialize_camera_node()
	engine.set_level(starting_level)

# --------------------------------------------------------------------------------------------------

func initialize_layers_node():
	if Engine.is_editor_hint():
		var layers = get_node("PTLayers")
		if layers != null:
			remove_child(layers)
		
		layers = PTLayers.new()
		layers.name = "PTLayers"
		add_child(layers)
		move_child(layers, 0)
		layers.set_owner(get_tree().get_edited_scene_root())
	
	$PTLayers.set_ldtk_project(ldtk_project_data)

func initialize_engine():	
	engine = PTEngine.new()
	engine.initialize(self, $PTLayers)
	engine.run_turns_on_keyup = run_turns_on_keyup
	engine.enable_mouse_turns = enable_mouse_turns
	engine.again_interval = again_interval
	engine.key_repeat_interval = key_repeat_interval
	engine.set_level(starting_level)

func initialize_camera_node():
	if Engine.is_editor_hint():
		for node in get_tree_nodes():
			if node.get_class() == "Camera2D":
				print("#-- camera already exists, will not create PTCamera --#")
				return
		
		var camera = PTCamera.new()
		camera.name = "PTCamera"
		camera.current = true
		camera.tile_size = ldtk_project_data.defaultGridSize
		add_child(camera)
		move_child(camera, 1)
		camera.set_owner(get_tree().get_edited_scene_root())

# --------------------------------------------------------------------------------------------------

func set_level(value):
	if ldtk_project_data == null:
		starting_level = value
		return
	if value >= ldtk_project_data.levels.size():
		value = ldtk_project_data.levels.size()-1
	if value < 0:
		value = 0
	
	if starting_level != value:
		starting_level = value
		engine.set_level(starting_level)

# --------------------------------------------------------------------------------------------------

func get_tree_nodes():
	var nodes = []
	get_tree_nodes_recursive(self, nodes)
	return nodes

func get_tree_nodes_recursive(node, collected_nodes):
	collected_nodes.push_back(node)
	for child in node.get_children():
		get_tree_nodes_recursive(child, collected_nodes)

# --------------------------------------------------------------------------------------------------

func _ready():
	is_ready = true
	
	if ldtk_project_resource == null:
		return
		
	print("#-- game ready, loading project --#")
	load_project()

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
	

func set_key_repeat_interval(value):
	key_repeat_interval = value
	if engine != null:
		engine.key_repeat_interval = value
		
func set_again_interval(value):
	again_interval = value
	if engine != null:
		engine.again_interval = value

func set_log_level(value):
	log_level = value
	logger.log_level = value
