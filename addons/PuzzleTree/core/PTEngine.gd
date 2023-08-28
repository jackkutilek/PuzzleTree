extends RefCounted
class_name PTEngine

var queued := []
var pressed_keys := []
var key_repeat_interval := 1.0
var time_since_last_press := 0.0
var run_turns_on_keyup := false
var mouse_cell = Vector2i()
var mouse_is_down = false
var enable_mouse_turns = false

var base_tile_size:Vector2i = Vector2i(5,5)

var again_interval := 1.0
var time_since_last_frame := 0.0
var againing := false

var realtime_interval := 0.0
var time_since_last_realtime_frame := 0.0

var turn_start_state = null
var state_to_save = null

var root: Node2D
var game_state: PTGameState
var ptproject: PuzzleTreeProject = null

const MAX_FRAMES_PER_PROCESS = 4
# ---------------------------------------------------------

func _unhandled_key_input(event: InputEvent):
	if event.pressed:
		match event.keycode:
			KEY_Z:
				abort_turn()
				if state_to_save != null:
					game_state.load_state(state_to_save)
					state_to_save = null
					turn_start_state = null
				else:
					game_state.undo()
				return true
			KEY_R:
				abort_turn()
				if state_to_save != null:
					game_state.load_state(state_to_save)
					state_to_save = null
					turn_start_state = null
				game_state.reset()
				return true
			KEY_C:
				game_state.redo()
				return true
			KEY_BRACKETLEFT:
				abort_turn()
				prev_level()
				return true
			KEY_BRACKETRIGHT:
				abort_turn()
				next_level()
				return true
			KEY_ESCAPE:
				root.get_tree().quit()
				return true
	
	if event.is_echo():
		return false

	match event.keycode:
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
		KEY_SPACE, KEY_X:
			if event.pressed:
				queue_input(Inputs.PRESS_ACTION)
			else:
				queue_input(Inputs.RELEASE_ACTION)
			return true
	
	return false

func _unhandled_input(event: InputEvent):
	if enable_mouse_turns:
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
				# TODO add all cells in between old and new cells
				queue_input(Inputs.MOUSE_MOVE)

func update_mouse_cell():
	var global = root.get_global_mouse_position()
	var local = root.to_local(global)
	mouse_cell = local_to_map(local)

func local_to_map(local:Vector2)->Vector2i:
	return Vector2i(int(local.x/base_tile_size.x), int(local.y/base_tile_size.y))

func queue_input(input: String):
	if game_state.context.frame.winning:
		return	# don't queue input during win wait time
	
	if Inputs.is_released_key(input) and not pressed_keys.has(Inputs.get_key_dir(input)):
		return
	if input == Inputs.MOUSE_UP and not mouse_is_down:
		return
		
	if Inputs.is_pressed_key(input):
		note_key_press(input)
	elif Inputs.is_released_key(input):
		note_key_release(input)
	
	if not run_turns_on_keyup and Inputs.is_released_key(input):
		return
	
	if not enable_mouse_turns and Inputs.is_mouse_key(input):
		return
	
	
	if input == Inputs.MOUSE_DOWN:
		mouse_is_down = true
	elif input == Inputs.MOUSE_UP:
		mouse_is_down = false
		
	logger.log(1, str("queue input ", input))
		
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
	if dir != null:
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
			logger.log(1, str("force released ", Directions.get_dir_string(dir)))
			pressed_keys.erase(dir)
			
			var new_queue = []
			for key in queued:
				var key_dir = Inputs.get_key_dir(key)
				if key_dir != dir:
					new_queue.append(key)
			queued = new_queue
	
	update_key_state_in_context()

func force_release_mouse():
	if mouse_is_down:
		mouse_is_down = false
	
		var new_queue = []
		for key in queued:
			if not Inputs.is_mouse_key(key):
				new_queue.append(key)
		queued = new_queue
		
	update_key_state_in_context()

func abort_turn():
	force_release_keys(pressed_keys)
	force_release_mouse()
	againing = false
	
# ---------------------------------------------------------

func get_count_of_queued_presses():
	var count = 0
	for key in queued:
		if Inputs.is_pressed_key(key) or key == Inputs.MOUSE_DOWN:
			count += 1
		if key == Inputs.MOUSE_MOVE and mouse_is_down:
			count += 1
	return count

func _process(delta:float):
	if game_state.context.frame.stop_for > 0:
		var time_to_stop = min(delta, game_state.context.frame.stop_for)
		game_state.context.frame.stop_for -= time_to_stop
		delta -= time_to_stop
	
	if delta < .0001:
		#print("no update because stopped")
		return
	
	time_since_last_frame += delta
	time_since_last_press += delta
	
	var computation_time = 0
	
	var queued_press_count = get_count_of_queued_presses()
	var frame_acceleration = 1.0/(1+queued_press_count)
	var frame_time = again_interval * frame_acceleration
	if againing:
		if time_since_last_frame > frame_time:
			var available_time = time_since_last_frame + delta
			var again_time = 0
			var count = 0
			while againing and (again_time + frame_time) < available_time and count < MAX_FRAMES_PER_PROCESS:
				var frame_execution_start = Time.get_ticks_usec()
				run_again_frame(frame_time)
				var frame_execution_time = Time.get_ticks_usec() - frame_execution_start
				computation_time += frame_execution_time
				again_time += frame_time
				count += 1
				if game_state.context.frame.stop_for > 0:
					return
				#TODO check if stopped and consume stop time if delta has time remaining
	else:
		var next = get_queued_input()
		if next != null:
			# process the queued input
			logger.log(1, str("#-- BEGIN TURN ", Inputs.get_key_string(next), " --#"))
			logger.log(1, str("#-- FIRST FRAME ", Inputs.get_key_string(next), " --#"))
			game_state.context.frame.is_repeat_turn = false
			update_key_state_in_context()
			run_frame(next)
			if next == Inputs.REALTIME:
				time_since_last_realtime_frame = 0.0
		elif pressed_keys.size() > 0:
			# check for key repeat turn
			var last_press = pressed_keys.back()
			if time_since_last_press > key_repeat_interval:
				logger.log(1, str("#-- REPEAT TURN ", last_press, " --#"))
				logger.log(1, str("#-- FIRST FRAME ", last_press, " --#"))
				game_state.context.frame.is_repeat_turn = true
				update_key_state_in_context()
				run_frame(Inputs.get_pressed_key(last_press))
				time_since_last_press = 0
		
		if realtime_interval > 0:
			if time_since_last_realtime_frame > realtime_interval:
				queue_input(Inputs.REALTIME)
			time_since_last_realtime_frame += delta

func run_again_frame(frame_time):
	logger.log(1, str("  #-- AGAIN FRAME in ", time_since_last_frame, " -- threshold: ", frame_time, " --#"))
	game_state.context.frame.is_repeat_turn = false
	run_frame(Inputs.AGAIN)

func run_frame(frame_key):
	var context = game_state.context
	
	# reset changed tiles
	for layer in game_state.layers.get_tile_layers().values():
		layer.reset_changed_cells()
	
	# apply turn reason to frame context
	reset_control_flags(context)
	context.frame.key = frame_key
	
	if not frame_key == Inputs.AGAIN:
		turn_start_state = game_state.gather_state()
	
	if Inputs.is_pressed_key(frame_key) or frame_key == Inputs.MOUSE_DOWN:
		if not context.frame.nosave:
			state_to_save = turn_start_state
			logger.log(1, str("turn start state set"))
		if context.frame.nosave:
			logger.log(1, str("nosave reset to false"))
			context.frame.nosave = false
	
	frame_update(context)
	
	context.frame.again = context.frame.again and not context.frame.cancel
	againing = context.frame.again
	
	if context.frame.force_release_all_keys:
		force_release_keys(Directions.ALL_DIRS)
		context.frame.force_release_all_keys = false
	
	if context.frame.force_release_keys.size() > 0:
		force_release_keys(context.frame.force_release_keys)
		context.frame.force_release_keys.clear()
	
	if context.frame.force_release_mouse:
		force_release_mouse()
		context.frame.force_release_mouse = false
	
	if context.frame.nosave:
		logger.log(1, str("no save"))
	
	if context.frame.cancel:
		game_state.load_state(turn_start_state)
		logger.log(1, str("#-- CANCEL TURN --#"))
		logger.log(1, str("#----#"))
	else:
		if state_to_save != null and not context.frame.again:
			# end of turn
			var end_state = game_state.gather_state()
			var turn_made_changes = state_to_save != end_state
			
			if turn_made_changes:
				game_state.save_state(state_to_save)
				logger.log(1, str("state saved"))
				
			if context.frame.checkpoint:
				game_state.set_checkpoint(end_state)
				logger.log(1, str("checkpoint set"))
			
			state_to_save = null
			logger.log(1, str("cleared turn start state"))
			logger.log(1, str("#-- END TURN --#"))
			logger.log(1, str("#----#"))
	
	if context.frame.winning:
		force_release_keys(Directions.ALL_DIRS)
		force_release_mouse()
		queued.clear()
		context.frame.again = false
		againing = false 
		if has_next_level():
			await root.get_tree().create_timer(1).timeout
			context.frame.winning = false
			next_level()
		else:
			context.frame.winning = false
	
	again_interval = context.frame.again_interval
	key_repeat_interval = context.frame.key_repeat_interval
		
	time_since_last_frame = 0

func reset_control_flags(context):
	if not context.has('frame'):
		context.frame = {}
	var frame = context.frame
	
	frame.again = false
	frame.cancel = false
	frame.finish_frame_early = false
	frame.winning = false
	frame.checkpoint = false
	frame.force_release_all_keys = false
	frame.force_release_keys = []
	frame.force_release_mouse = false
	
	frame.stop_for = 0
	frame.again_interval = again_interval
	frame.key_repeat_interval = key_repeat_interval

func update_key_state_in_context():
	var frame = game_state.context.frame
	frame.pressed_keys = []
	frame.pressed_keys.append_array(pressed_keys)
	
	frame.mouse_cell = mouse_cell
	frame.mouse_is_down = mouse_is_down
	

func _on_game_state_state_loaded():
	reset_update()

# ---------------------------------------------------------

func init_update():
	reset_control_flags(game_state.context)
	game_state.context.frame.key = null
	game_state.context.frame.nosave = false
	
	for node in get_tree_nodes():
		if node.has_method('init_update'):
			node.init_update(game_state.context)
	for node in get_tree_nodes():
		if node.has_method('late_init_update'):
			node.late_init_update(game_state.context)

func reset_update():
	reset_control_flags(game_state.context)
	game_state.context.frame.key = null
	
	for node in get_tree_nodes():
		if node.has_method('reset_update'):
			node.reset_update(game_state.context)
	for node in get_tree_nodes():
		if node.has_method('late_reset_update'):
			node.late_reset_update(game_state.context)

func frame_update(context):
	for node in get_tree_nodes():
		if context.frame.cancel:
			logger.log(1, str("    cancel"))
			break
		if context.frame.finish_frame_early:
			logger.log(1, str("    finish early"))
			break
		if node.has_method("frame_update"):
			node.frame_update(context)
	if not context.frame.cancel and not context.frame.finish_frame_early:
		logger.log(2, str("    #-- run late update --#"))
		for node in get_tree_nodes():
			if context.frame.cancel:
				logger.log(1, str("    cancel"))
				break
			if context.frame.finish_frame_early:
				logger.log(1, str("    finish early"))
				break
			if node.has_method("late_frame_update"):
				node.late_frame_update(context)

# ---------------------------------------------------------

func get_tree_nodes()->Array[Node]:
	var nodes:Array[Node] = []
	get_tree_nodes_recursive(root, nodes)
	return nodes

func get_tree_nodes_recursive(node: Node, collected_nodes: Array[Node]):
	collected_nodes.push_back(node)
	for child in node.get_children():
		get_tree_nodes_recursive(child, collected_nodes)

# ---------------------------------------------------------

func switch_to_level(id:int):
	var levels_size = 1
	if ptproject != null:
		levels_size = ptproject.levels.size()
	if id >= levels_size:
		id = levels_size-1
	if id < 0:
		id = 0
	
	if game_state.current_level_id != id:
		print("switch to level ", id)
		load_level(id)

func load_level(id:int, initial_context={}):
	print("switch to level ", id)
	game_state.load_level(id, initial_context)
	
	if not Engine.is_editor_hint():
		logger.log(1, str("init update"))
		init_update()
		game_state.save_state(game_state.gather_state())
		logger.log(1, str("init update saved"))

func next_level():
	switch_to_level(game_state.current_level_id+1)

func prev_level():
	switch_to_level(game_state.current_level_id-1)

func has_next_level():
	var levels_size = 1
	if ptproject != null:
		levels_size = ptproject.levels.size()
	return game_state.current_level_id+1 < levels_size

# ---------------------------------------------------------

func initialize(pRoot: Node2D, layers: PTLayers):
	root = pRoot
	ptproject = layers.ptproject
	game_state = PTGameState.new()
	game_state.initialize(layers)
	var _err = game_state.connect("state_loaded",_on_game_state_state_loaded)
