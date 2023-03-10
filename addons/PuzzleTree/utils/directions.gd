extends Node

const LEFT = 'left'
const RIGHT = 'right'
const UP = 'up'
const DOWN = 'down'

const ALL_DIRS = [UP, DOWN, LEFT, RIGHT]

# --------------------------------------------------------------------------------------------------
func dir_from_index(index:int):
	return ALL_DIRS[index]

func get_dir_index(dir):
	match dir:
		UP:
			return 0
		DOWN:
			return 1
		LEFT:
			return 2
		RIGHT:
			return 3

func get_dir_string(dir):
	match dir:
		UP:
			return "UP"
		DOWN:
			return "DOWN"
		LEFT:
			return "LEFT"
		RIGHT:
			return "RIGHT"

func is_perpendicular_to(dir, to):
	match dir:
		UP, DOWN:
			return to == LEFT or to == RIGHT
		LEFT, RIGHT:
			return to == UP or to == DOWN

# --------------------------------------------------------------------------------------------------

func opposite(dir):
	match dir:
		UP:
			return DOWN
		DOWN:
			return UP
		LEFT:
			return RIGHT
		RIGHT:
			return LEFT

func rotate_cw(dir):
	match dir:
		UP:
			return RIGHT
		DOWN:
			return LEFT
		LEFT:
			return UP
		RIGHT:
			return DOWN
			
func rotate_ccw(dir):
	match dir:
		UP:
			return LEFT
		DOWN:
			return RIGHT
		LEFT:
			return DOWN
		RIGHT:
			return UP

# --------------------------------------------------------------------------------------------------

func shift_coords(x,y,dir):
	match dir:
		UP:
			return [x,y-1]
		DOWN:
			return [x,y+1]
		LEFT:
			return [x-1,y]
		RIGHT:
			return [x+1,y]

func shift_cell(cell, dir):
	match dir:
		UP:
			return Vector2i(cell.x,cell.y-1)
		DOWN:
			return Vector2i(cell.x,cell.y+1)
		LEFT:
			return Vector2i(cell.x-1,cell.y)
		RIGHT:
			return Vector2i(cell.x+1,cell.y)

func get_neighbor_cells(cell):
	return {
		left=shift_cell(cell, LEFT),
		right = shift_cell(cell, RIGHT),
		up = shift_cell(cell, UP),
		down = shift_cell(cell, DOWN)
	}

# --------------------------------------------------------------------------------------------------
# index: [transpose, flipx, flipy]
var dir_index_to_flips = [
	[false, false, false], # UP
	[false, false, true ], # DOWN
	[true,  false,  false], # LEFT
	[true,  true, false] # RIGHT
]

# direction: [transpose, flipx, flipy]
var dir_to_flips = {
	DOWN:  [false, false, true ],
	RIGHT: [true,  true, false],
	LEFT:  [true,  false,  false],
	UP:    [false, false, false]
}

func get_tile_settings(dir):
	var flipx
	var flipy
	var transpose
	match dir:
		DOWN:
			flipx = false
			flipy = true
			transpose = false
		RIGHT:
			flipx = true
			flipy = false
			transpose = true
		LEFT:
			flipx = false
			flipy = false
			transpose = true
		UP: 
			flipx = false
			flipy = false
			transpose = false
	return {flipx= flipx, flipy= flipy, transpose= transpose}

func get_tile_dir(flipx, flipy, transpose):
	if not flipx and flipy and not transpose:
		return DOWN
	if flipx and not flipy and transpose:
		return RIGHT
	if not flipx and not flipy and transpose:
		return LEFT
	if not flipx and not flipy and not transpose:
		return UP
	assert(false)
	
	
