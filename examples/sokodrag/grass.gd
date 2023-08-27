extends Node2D

@onready var start:PTEntities = get_node("%Start")
@onready var reach:PTTiles = get_node("%Reach")
@onready var grid:PTTiles = get_node("%Grid")

const GRASS = 0
const DIRT = 1
const CRATE = 2
const TARGET = 3
const WALL = 4

func init_update(context):
	initialize_dirt(context)
	
	var start_cell = start.entities[0].cell
	reach.set_tile_at_cell(GRASS, start_cell)
	context.player_cell = start_cell
	context.next_player_cell = null
	
	context.to_update = []
	
	initialize_grass(context, start_cell)
	pass

# Called once during each frame
func frame_update(context):
	if context.next_player_cell != null:
		var offset = context.frame.mouse_cell - context.next_player_cell
		var test_cell = context.next_player_cell - offset
		
		context.player_cell = context.next_player_cell
		context.next_player_cell = null
		
		initialize_new_grass(context, test_cell)
		
		context.updated_cells = {}
		context.to_update = [test_cell]
		pass
	pass

func late_frame_update(context):
	if context.to_update.size() > 0:
		var next_update = []
		for cell in context.to_update:
			var is_grass = reach.has_tile_at_cell(GRASS, cell)
			var is_dirt = reach.has_tile_at_cell(DIRT, cell)
			var is_new_grass = context.new_grass.has(cell)
			
			if is_new_grass and is_dirt:
				reach.set_tile_at_cell(GRASS, cell)
			elif not is_new_grass and is_grass:
				reach.set_tile_at_cell(DIRT, cell)
			
			context.updated_cells[cell] = true
			
			for dir in Directions.ALL_DIRS:
				var neighbor = Directions.shift_cell(cell, dir)
				if context.updated_cells.has(neighbor):
					continue
				if grid.has_tile_at_cell(WALL, neighbor):
					continue
				if not cell_is_in_level_bounds(neighbor, context):
					continue
				
				next_update.append(neighbor)
			
		if next_update.size() > 0:
			context.frame.again = true
			context.to_update = next_update
			
	pass

func spread_grass(context, from):
	for cell in reach.get_cells_with_tile(GRASS):
		for dir in Directions.ALL_DIRS:
			var neighbor = Directions.shift_cell(cell, dir)
			var has_crate = grid.has_tile_at_cell(CRATE, neighbor)
			var has_dirt = reach.has_tile_at_cell(DIRT, neighbor)
			if not has_crate and has_dirt:
				reach.set_tile_at_cell(GRASS, neighbor)
				context.frame.again = true


func initialize_new_grass(context, start):
	context.new_grass = {}
	if reach.has_tile_at_cell(DIRT, start):
		return
	
	var cells = [start]
	while cells.size() > 0:
		var cell = cells.pop_back()
		if not cell_can_have_grass(cell, context):
			continue
			
		context.new_grass[cell] = true
		
		for dir in Directions.ALL_DIRS:
			var neighbor = Directions.shift_cell(cell, dir)
			var visited = context.new_grass.has(neighbor)
			if visited:
				continue
			
			if cell_can_have_grass(neighbor, context):
				cells.push_back(neighbor)

func initialize_grass(context, start):
	var cells = [start]
	while cells.size() > 0:
		var cell = cells.pop_back()
		reach.set_tile_at_cell(GRASS, cell)
		
		for dir in Directions.ALL_DIRS:
			var neighbor = Directions.shift_cell(cell, dir)
			var has_crate = grid.has_tile_at_cell(CRATE, neighbor)
			var has_dirt = reach.has_tile_at_cell(DIRT, neighbor)
			if not has_crate and has_dirt:
				cells.push_back(neighbor)
	

func initialize_dirt(context):
	var player_cell = start.entities[0].cell
	var cells = [player_cell]
	while cells.size() > 0:
		var cell = cells.pop_back()
		reach.set_tile_at_cell(DIRT, cell)
		
		for dir in Directions.ALL_DIRS:
			var neighbor = Directions.shift_cell(cell, dir)
			var has_wall = grid.has_tile_at_cell(WALL, neighbor)
			var has_dirt = reach.has_tile_at_cell(DIRT, neighbor)
			if not has_dirt and not has_wall:
				cells.push_back(neighbor)
				
		
func cell_can_have_grass(cell:Vector2i, context):
	var has_wall = grid.has_tile_at_cell(WALL, cell)
	var has_crate = grid.has_tile_at_cell(CRATE, cell)
	var in_bounds = cell_is_in_level_bounds(cell, context)
	return not has_wall and not has_crate and in_bounds
	

func cell_is_in_level_bounds(cell:Vector2i, context):
	return cell.x >= 0 and cell.y >= 0 and cell.x < context._level_width and cell.y < context._level_height
