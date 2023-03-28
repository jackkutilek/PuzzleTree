@tool
@icon("../icons/PTMovement.png")
extends Node2D
class_name PTMovement

var moves = []
var moves_made = []

func _enter_tree():
	unique_name_in_owner = true

# --------------------------------------------------------------------------------------------------

func queue_move(layer: PTTiles, cell: Vector2i, dir: String, extraCollisionLayers: Array = []):
	moves.append({layer=layer, cell=cell, dir=dir, extraCollisionLayers=extraCollisionLayers})

func copy_move_to(move:Dictionary, cell: Vector2i):
	moves.append({layer=move.layer, cell=cell, dir=move.dir, extraCollisionLayers=move.extraCollisionLayers})

func has_move_at(layer: PTTiles, cell: Vector2i):
	return get_move_at(layer, cell) != null

func get_move_at(layer: PTTiles, cell: Vector2i):
	for move in moves:
		if move.layer == layer and move.cell == cell:
			return move
	return null

func unqueue_move(move):
	moves.erase(move)

func unqueue_move_at(layer: PTTiles, cell: Vector2i):
	var move = get_move_at(layer, cell)
	unqueue_move(move)

# --------------------------------------------------------------------------------------------------

func frame_update(_context):
	moves_made.clear()
	
	var did_move = true
	while did_move:
		did_move = false
		for move in moves:
			var layer = move.layer as PTTiles
			var cell = move.cell
			var dir = move.dir
			var dest_cell = Directions.shift_cell(cell, dir)
			
			if layers_are_empty(layer, move.extraCollisionLayers, dest_cell):
				var tile = layer.get_tiles_at_cell(cell)[0]
				var tile_dir = layer.get_tile_dir_at_cell(tile, cell)
				layer.clear_cell(cell)
				layer.stack_tile_at_cell(tile, dest_cell, tile_dir)
				moves.erase(move)
				moves_made.push_back(move)
				did_move = true
	
	moves.clear()


func layers_are_empty(layer:PTTiles, extra_layers:Array, cell: Vector2i):
	if layer.any_tile_at_cell(cell):
		return false
	for extra_layer in extra_layers:
		if extra_layer.any_tile_at_cell(cell):
			return false
	return true
