extends Node

# --------------------------------------------------------------------------------------------------

const PRESS_UP = 'press up'
const PRESS_DOWN = 'press down'
const PRESS_LEFT = 'press left'
const PRESS_RIGHT = 'press right'
const RELEASE_UP = 'release up'
const RELEASE_DOWN = 'release down'
const RELEASE_LEFT = 'release left'
const RELEASE_RIGHT = 'release right'

const PRESS_ACTION = 'action'
const RELEASE_ACTION = 'action'

const MOUSE_DOWN = 'mouse down'
const MOUSE_UP = 'mouse up'
const MOUSE_MOVE = 'mouse move'

const AGAIN = 'again'
const REALTIME = 'realtime'

# --------------------------------------------------------------------------------------------------

func is_pressed_key(key):
	match key:
		PRESS_DOWN, PRESS_UP, PRESS_RIGHT, PRESS_LEFT, PRESS_ACTION:
			return true
	return false
	
func is_released_key(key):
	match key:
		RELEASE_DOWN, RELEASE_UP, RELEASE_RIGHT, RELEASE_LEFT, RELEASE_ACTION:
			return true
	return false

func is_mouse_key(key):
	match key:
		MOUSE_DOWN, MOUSE_UP, MOUSE_MOVE:
			return true
	return false

# --------------------------------------------------------------------------------------------------

func get_key_dir(key):
	match key:
		PRESS_UP, RELEASE_UP:
			return Directions.UP
		PRESS_DOWN, RELEASE_DOWN:
			return Directions.DOWN
		PRESS_RIGHT, RELEASE_RIGHT:
			return Directions.RIGHT
		PRESS_LEFT, RELEASE_LEFT:
			return Directions.LEFT
		_:
			return null

func get_pressed_key(dir):
	match dir:
		Directions.LEFT:
			return PRESS_LEFT
		Directions.RIGHT:
			return PRESS_RIGHT
		Directions.UP:
			return PRESS_UP
		Directions.DOWN:
			return PRESS_DOWN
		_:
			return null

func get_key_string(key):
	match key:
		PRESS_UP:
			return "PRESS_UP"
		PRESS_DOWN:
			return "PRESS_DOWN"
		PRESS_LEFT:
			return "PRESS_LEFT"
		PRESS_RIGHT:
			return "PRESS_RIGHT"
		RELEASE_UP:
			return "RELEASE_UP"
		RELEASE_DOWN:
			return "RELEASE_DOWN"
		RELEASE_LEFT:
			return "RELEASE_LEFT"
		RELEASE_RIGHT:
			return "RELEASE_RIGHT"
		AGAIN:
			return "AGAIN"
		_:
			return key
