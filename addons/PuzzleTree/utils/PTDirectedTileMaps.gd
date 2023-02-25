extends Node2D
class_name GPSDirectedTileMaps, "../icons/gpsdirectedtilemaps.png"

export var tile_set: TileSet
export var cell_size: Vector2 = Vector2(5,5)

# direction: [transpose, flipx, flipy]
var dir_to_flips = {
	Directions.LEFT:  [true,  false,  false],
	Directions.RIGHT: [true,  true, false],
	Directions.DOWN:  [false, false, true ],
	Directions.UP:    [false, false, false]
}

var tilemaps
var dir_to_tilemap

# --------------------------------------------------------------------------------------------------

func set_dir_at(tile, dir, cell:Vector2):
	var map = dir_to_tilemap[dir]
	var flags = dir_to_flips[dir]
	map.set_cellv(cell, tile, flags[1], flags[2], flags[0])

func erase_dir_at(dir, cell):
	var map = dir_to_tilemap[dir]
	map.set_cellv(cell, -1)

func clear_at(cell):
	for map in tilemaps:
		map.set_cellv(cell, -1)

func clear():
	for map in tilemaps:
		for cell in map.get_used_cells():
			map.set_cellv(cell, -1)
		
# --------------------------------------------------------------------------------------------------

func has_dir_at(dir, cell):
	var map = dir_to_tilemap[dir]
	return map.get_cellv(cell) != -1

func has_anything_at(cell):
	for map in tilemaps:
		if map.get_cellv(cell) != -1:
			return true
	return false

func get_used_cells():
	var cells = {}
	for map in tilemaps:
		for cell in map.get_used_cells():
			cells[cell] = true
	return cells.keys()

# --------------------------------------------------------------------------------------------------

func createTileMap(name:String):
	var map = TileMap.new()
	map.tile_set = tile_set
	map.cell_size = cell_size
	map.name = name
	add_child(map)
	return map

# --------------------------------------------------------------------------------------------------

func _ready():
	var left = createTileMap("Left")
	var right = createTileMap("Right")
	var up = createTileMap("Up")
	var down = createTileMap("Down")
	
	tilemaps = [left, up, down, right]
	dir_to_tilemap =  {
		Directions.LEFT: left,
		Directions.RIGHT: right,
		Directions.DOWN: down,
		Directions.UP: up
	}

func copy_tilemap_settings_from(tilemap):
	tile_set = tilemap.tile_set
	cell_size = tilemap.cell_size
