@tool
extends Node


var tile_sets: Dictionary = {}


func get_tile_set(texture: Texture2D, tile_size: Vector2i) -> TileSet:
	var key = _get_key(texture, tile_size)
	if tile_sets.has(key):
		return tile_sets[key]
	
	var tileset = create_tileset(texture, tile_size)
	tile_sets[key] = tileset
	return tileset

func _get_key(texture: Texture2D, tile_size: Vector2i)->String:
	return "%d %d %d" % [texture.get_rid().get_id(), tile_size.x, tile_size.y]

static func create_tileset(texture: Texture2D, tile_size: Vector2i)->TileSet:
	print ("creating tileset")
	var tileset = TileSet.new()
	tileset.tile_size = tile_size
	
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile_size
	
	var tile_y_count = source.texture.get_height() / tile_size.y
	var tile_x_count = source.texture.get_width() / tile_size.x
	
	for y in range(tile_y_count):
		for x in range(tile_x_count):
			var atlas_id = Vector2i(x, y)
			source.create_tile(atlas_id, Vector2i(1,1))
			for di in [1,2,3]:
				source.create_alternative_tile(atlas_id)
				var data = source.get_tile_data(atlas_id, di)
				var settings = dir_index_to_flips[di]
				data.transpose = settings[0]
				data.flip_h = settings[1]
				data.flip_v = settings[2]
	
	tileset.add_source(source)
	return tileset

# index: [transpose, flipx, flipy]
const dir_index_to_flips = [
	[false, false, false], # UP
	[false, false, true ], # DOWN
	[true,  false,  false], # LEFT
	[true,  true, false] # RIGHT
]
