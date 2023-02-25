extends Reference
class_name PTEngine

var log_level = 0

var queued := []
var pressed_keys := []
var key_repeat_interval := 1.0
var time_since_last_press := 0.0
var run_turns_on_keyup := false
var mouse_cell = Vector2()
var mouse_is_down = false
var enable_mouse_turns = false

var again_interval := 1.0
var time_since_last_frame := 0.0
var againing := false
var turn_start_state = null
var state_to_save = null

var root: Node2D
var game_state: PTGameState
var ldtk_project_data = null

# ---------------------------------------------------------

func _unhandled_key_input(event: InputEventKey):
	if event.pressed:
		match event.scancode:
			KEY_Z:
				abort_turn()
				game_state.undo()
				return true
			KEY_R:
				abort_turn()
				game_state.reset()
				return true
			KEY_BRACKETLEFT:
				abort_turn()
				prev_level()
				return true
			KEY_BRACKETRIGHT:
				abort_turn()
				next_level()
				return true
	
	if event.is_echo():
		return false

	match event.scancode:
		KEY_UP, KEY_W:
			if event.pressed:
				queue_input(Inputs.PRESS_UP)
			else:
				queue_input(Inputs.RELEASE_UP)
			return true
		KEY_DOWN, KEY_S:
			if event.pressed:
				queue_input(Inputs.PRESS_DOWN)
			else:
				queue_input(Inputs.RELEASE_DOWN)
			return true
		KEY_LEFT, KEY_A:
			if event.pressed:
				queue_input(Inputs.PRESS_LEFT)
			else:
				queue_input(Inputs.RELEASE_LEFT)
			return true
		KEY_RIGHT, KEY_D:
			if event.pressed:
				queue_input(Inputs.PRESS_RIGHT)
			else:
				queue_input(Inputs.RELEASE_RIGHT)
			return true
	
	return false

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			update_mouse_cell()
			if event.is_pressed():
				queue_input(Inputs.MOUSE_DOWN)
			else:
				queue_input(Inputs.MOUSE_UP)
			return true
	
	if event is InputEventMouseMotion:
		var old_cell = mouse_cell
		update_mouse_cell()
		if old_cell != mouse_cell:
			queue_input(Inputs.MOUSE_MOVE)

func update_mouse_cell():
	var layer = game_state.layers.get_child(0) as TileMap
	var mouse_pos = layer.get_global_mouse_position()
	var local_position = layer.to_local(mouse_pos)
	mouse_cell = layer.world_to_map(local_position)

func queue_input(input: String):
	if Inputs.is_pressed_key(input):
		note_key_press(input)
	else:
		note_key_release(input)
		
	if not run_turns_on_keyup and Inputs.is_released_key(input):
		return
	
	if not enable_mouse_turns and Inputs.is_mouse_key(input):
		return
		
	if input == Inputs.MOUSE_DOWN:
		mouse_is_down = true
	elif input == Inputs.MOUSE_UP:
		mouse_is_down = false
		
	if log_level > 0:
		print("queue input ", input)
		
	queued.push_back(input)

func get_queued_input():
	if queued.size() > 0:
		var input = queued.pop_front()
		return input
	else:
		return null

func note_key_press(input):
	time_since_last_press = 0
	var dir = Inputs.get_key_dir(input)
	if pressed_keys.has(dir):
		pressed_keys.erase(dir)
	pressed_keys.push_back(dir)

func note_key_release(input):
	var dir = Inputs.get_key_dir(input)
	if pressed_keys.has(dir):
		pressed_keys.erase(dir)
		return true
	return false

func force_release_keys(keys):
	for dir in keys:
		if pressed_keys.has(dir):
			if log_level > 0:
				print("force released ", Directions.get_dir_string(dir))
			pressed_keys.erase(dir)
			
			var new_queue = []
			for key in queued:
				var key_dir = Inputs.get_key_dir(key)
				if key_dir != dir:
					new_queue.append(key)
			queued = new_queue
				

func abort_turn():
	force_release_keys(pressed_keys)
	againing = false
	
# ---------------------------------------------------------

func _process(delta:float):
	time_since_last_frame += delta
	time_since_last_press += delta
	
	var frame_time = again_interval
	if againing:
		# run an again turn
		if time_since_last_frame > frame_time:
			if log_level > 0:
				print("  #-- AGAIN FRAME --#")
			game_state.context.is_repeat_turn = false
			run_frame(Inputs.AGAIN)
	else:
		var next = get_queued_input()
		if next != null:
			# process the queued input
			if log_level > 0:
				print("#-- BEGIN TURN ", Inputs.get_key_string(next), " --#")
				print("#-- FIRST FRAME ", Inputs.get_key_string(next), " --#")
			game_state.context.is_repeat_turn = false
			update_key_state_in_context()
			run_frame(next)
		elif pressed_keys.size() > 0:
			# check for key repeat turn
			var last_press = pressed_keys.back()
			if time_since_last_press > key_repeat_interval:
				if log_level > 0:
					print("#-- REPEAT TURN ", last_press, " --#")
					print("#-- FIRST FRAME ", last_press, " --#")
				game_state.context.is_repeat_turn = true
				update_key_state_in_context()
				run_frame(Inputs.get_pressed_key(last_press))
				time_since_last_press = 0


func run_frame(frame_key):
	var context = game_state.context
	
	# reset changed tiles
	for layer in game_state.layers.get_tile_layers():
		layer.reset_changed_cells()
	
	# apply turn reason to frame context
	reset_control_flags(context)
	context.frame_key = frame_key
	
	if not frame_key == Inputs.AGAIN:
		turn_start_state = game_state.gather_state()
	
	if Inputs.is_pressed_key(frame_key) or frame_key == Inputs.MOUSE_DOWN:
		if not context.nosave:
			state_to_save = turn_start_state
			if log_level > 0:
				print("turn start state set")
		if context.nosave:
			if log_level > 0:
				print("nosave reset to false")
			context.nosave = false
	
	frame_update(context)
	
	context.again = context.again and not context.cancel
	againing = context.again
	
	if context.force_release_all_keys:
		force_release_keys(Directions.ALL_DIRS)
		context.force_release_all_keys = false
	
	if context.force_release_keys.size() > 0:
		force_release_keys(context.force_release_keys)
		context.force_release_keys.clear()
	
	if log_level > 0:
		if context.nosave:
			print("no save")
	
	if context.cancel:
		game_state.load_state(turn_start_state)
		if log_level > 0:
			print("#-- CANCEL TURN --#")
			print("#----#")
	else:
		if state_to_save != null and not context.again:
			# end of turn
			var end_state = game_state.gather_state()
			var turn_made_changes = not deep_equal(state_to_save, end_state)
			
			if turn_made_changes:
				game_state.save_state(state_to_save)
				if log_level > 0:
					print("state saved")
				
			if context.checkpoint:
				game_state.set_checkpoint(end_state)
				if log_level > 0:
					print("checkpoint set")
			
			state_to_save = null
			if log_level > 0:
				print("cleared turn start state")
				print("#-- END TURN --#")
				print("#----#")
	
	if context.winning:
		yield(root.get_tree().create_timer(1), "timeout")
		next_level()
	
	again_interval = context.again_interval
	key_repeat_interval = context.key_repeat_interval
		
	time_since_last_frame = 0

func reset_control_flags(context):
	context.again = false
	context.cancel = false
	context.finish_frame_early = false
	context.winning = false
	context.checkpoint = false
	context.force_release_all_keys = false
	context.force_release_keys = []
	
	context.again_interval = again_interval
	context.key_repeat_interval = key_repeat_interval

func update_key_state_in_context():
	var context = game_state.context
	context.pressed_keys = []
	context.pressed_keys.append_array(pressed_keys)
	
	context.mouse_cell = mouse_cell
	context.mouse_is_down = mouse_is_down
	

func _on_game_state_state_loaded():
	reset_update()

# ---------------------------------------------------------

func init_update():
	reset_control_flags(game_state.context)
	game_state.context.frame_key = null
	game_state.context.nosave = false
	
	for node in get_tree_nodes():
		if node.has_method('init_update'):
			node.init_update(game_state.context)
	for node in get_tree_nodes():
		if node.has_method('late_init_update'):
			node.late_init_update(game_state.context)

func reset_update():
	reset_control_flags(game_state.context)
	game_state.context.frame_key = null
	
	for node in get_tree_nodes():
		if node.has_method('reset_update'):
			node.reset_update(game_state.context)
	for node in get_tree_nodes():
		if node.has_method('late_reset_update'):
			node.late_reset_update(game_state.context)

func frame_update(context):
	for node in get_tree_nodes():
		if context.cancel:
			if log_level > 0:
				print("    cancel")
			break
		if context.finish_frame_early:
			if log_level > 0:
				print("    finish early")
			break
		if node.has_method("frame_update"):
			node.frame_update(context)
	if not context.cancel and not context.finish_frame_early:
		if log_level > 1:
			print("    #-- run late update --#")
		for node in get_tree_nodes():
			if context.cancel:
				if log_level > 0:
					print("    cancel")
				break
			if context.finish_frame_early:
				if log_level > 0:
					print("    finish early")
				break
			if node.has_method("late_frame_update"):
				node.late_frame_update(context)

# ---------------------------------------------------------

func get_tree_nodes():
	var nodes = []
	get_tree_nodes_recursive(root, nodes)
	return nodes

func get_tree_nodes_recursive(node, collected_nodes):
	collected_nodes.push_back(node)
	for child in node.get_children():
		get_tree_nodes_recursive(child, collected_nodes)

# ---------------------------------------------------------

func set_level(id):
	if id >= ldtk_project_data.levels.size():
		id = ldtk_project_data.levels.size()-1
	if id < 0:
		id = 0
	
	if game_state.current_level_id != id:
		game_state.set_level(id)
		if not Engine.editor_hint:
			if log_level > 0:
				print("init update")
			init_update()
			game_state.save_state(game_state.gather_state())
			if log_level > 0:
				print("init update saved")

func next_level():
	set_level(game_state.current_level_id+1)
	
func prev_level():
	set_level(game_state.current_level_id-1)

# ---------------------------------------------------------

func initialize(pRoot: Node2D, layers: PTLayers):
	root = pRoot
	ldtk_project_data = layers.ldtk_project_data
	game_state = PTGameState.new()
	game_state.initialize(layers)
	var _err = game_state.connect("state_loaded", self, "_on_game_state_state_loaded")
