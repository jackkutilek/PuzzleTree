tool
extends Node2D
class_name PTMovement, "../icons/PTMovement.png"

var moves = []
var moves_made = []

func _enter_tree():
	unique_name_in_owner = true

# --------------------------------------------------------------------------------------------------

func queue_move(layer: PTTiles, cell: Vector2, dir: String, extraCollisionLayers: Array = []):
	moves.append({layer=layer, cell=cell, dir=dir, extraCollisionLayers=extraCollisionLayers})

func copy_move_to(move:Dictionary, cell: Vector2):
	moves.append({layer=move.layer, cell=cell, dir=move.dir, extraCollisionLayers=move.extraCollisionLayers})

func has_move_at(layer: PTTiles, cell: Vector2):
	return get_move_at(layer, cell) != null

func get_move_at(layer: PTTiles, cell: Vector2):
	for move in moves:
		if move.layer == layer and move.cell == cell:
			return move
	return null

func unqueue_move(move):
	moves.erase(move)

func unqueue_move_at(layer: PTTiles, cell: Vector2):
	var move = get_move_at(layer, cell)
	unqueue_move(move)

# --------------------------------------------------------------------------------------------------

func frame_update(_context):
	moves_made.clear()
	
	var did_move = true
	while did_move:
		did_move = false
		for move in moves:
			var layer = move.layer
			var cell = move.cell
			var dir = move.dir
			var dest_cell = Directions.shift_cell(cell, dir)
			
			if layers_are_empty(layer, move.extraCollisionLayers, dest_cell):
				var tile = layer.get_cellv(cell)
				layer.set_cellv(cell, -1)
				layer.set_cellv(dest_cell, tile)
				moves.erase(move)
				moves_made.push_back(move)
				did_move = true
	
	moves.clear()


func layers_are_empty(layer:PTTiles, extra_layers:Array, cell: Vector2):
	if layer.any_tile_at_cell(cell):
		return false
	for extra_layer in extra_layers:
		if extra_layer.any_tile_at_cell(cell):
			return false
	return true
