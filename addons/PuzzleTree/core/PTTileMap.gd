@tool
extends Node2D

class_name PTTileMap

@export var tile_set: Texture2D
@export var cell_size:int = 5

var grid = {}

func _draw():
	for cell in grid.keys():
		draw_tile_at(grid[cell], cell)

func get_rect(index:int):
	var size = tile_set.get_size()
	var tiles_width = int(size.x / cell_size)
	var tiles_height = int(size.y / cell_size)
	var x = (index)%tiles_width * cell_size
	var y = int(index/tiles_width) * cell_size
	return Rect2(x,y,cell_size, cell_size)

func draw_tile_at(tile, cell:Vector2i):
	var src_rect = get_rect(tile.id)
	src_rect = src_rect.grow(-.0001) # fix for texture bleeding at ceratin zoom scales
	
	var pos = Vector2(cell)*cell_size
	var size = Vector2(tile.x_flipped, tile.y_flipped)*cell_size
	var dest = Rect2(pos, size)
	
	draw_texture_rect_region(tile_set, dest, src_rect, Color(1,1,1,1), tile.transposed, false)

func get_used_cells(tile:int = -1):
	if tile == -1:
		return grid.keys()
	else:
		var keys = grid.keys()
		var result = []
		for key in keys:
			if grid[key].id == tile:
				result.append(key)
		return result

func get_cellv(cell:Vector2i):
	if grid.has(cell):
		return grid[cell].id
	else:
		return -1
	
func is_cell_x_flipped(x:int, y:int):
	var cell = Vector2i(x,y)
	if not grid.has(cell):
		return false
	return grid[cell].x_flipped < 0

func is_cell_y_flipped(x:int, y:int):
	var cell = Vector2i(x,y)
	if not grid.has(cell):
		return false
	return grid[cell].y_flipped < 0

func is_cell_transposed(x:int, y:int):
	var cell = Vector2i(x,y)
	if not grid.has(cell):
		return false
	return grid[cell].transposed

func set_cellv(cell:Vector2i, tile: int, x_flipped=false, y_flipped=false, transposed=false):
	if tile == -1:
		grid.erase(cell)
	else:
		grid[cell] = {id=tile, x_flipped=-1 if x_flipped else 1,y_flipped=-1 if y_flipped else 1,transposed=transposed}
	queue_redraw()
	pass

func clear():
	grid = {}
	queue_redraw()
	pass

func local_to_map(vec:Vector2):
	return vec/cell_size

func map_to_local(vec:Vector2):
	return vec*cell_size
