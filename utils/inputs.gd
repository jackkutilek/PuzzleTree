extends Node

const Directions = preload("directions.gd")

# --------------------------------------------------------------------------------------------------

enum {PRESS_UP, PRESS_DOWN, PRESS_LEFT, PRESS_RIGHT, RELEASE_UP, RELEASE_DOWN, RELEASE_LEFT, RELEASE_RIGHT, AGAIN}

# --------------------------------------------------------------------------------------------------

static func is_pressed_key(key):
	match key:
		PRESS_DOWN, PRESS_UP, PRESS_RIGHT, PRESS_LEFT:
			return true
	return false
	
static func is_released_key(key):
	match key:
		RELEASE_DOWN, RELEASE_UP, RELEASE_RIGHT, RELEASE_LEFT:
			return true
	return false

# --------------------------------------------------------------------------------------------------

static func get_key_dir(key):
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

static func get_key_string(key):
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
