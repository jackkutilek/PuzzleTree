extends Node2D

const Tiles = preload("tiles.gd")

onready var main = get_node("%Main")
onready var targets = get_node("%Targets")
onready var gates = get_node("%Gates")

var nodes: PTTiles

# Called once when a level starts
func init_update(_context):
	$nodes.copy_tilemap_settings_from(main)
	$wires.copy_tilemap_settings_from(main)
	
	rewire_crates()

func any_crate_exists_at(layer, cell):
	return layer.has_tile_at_cell(Tiles.CRATE, cell) or layer.has_tile_at_cell(Tiles.CRATE_WIRED, cell)

# Called at the end of each turn
func late_frame_update(_context):
	rewire_crates()


func get_wire_tile(color):
	match color:
		'yellow':
			return Tiles.YELLOW_WIRE
		'red':
			return Tiles.RED_WIRE
		'green':
			return Tiles.GREEN_WIRE
		_:
			return -1

func get_node_tile(color):
	match color:
		'yellow':
			return Tiles.YELLOW_NODE
		'red':
			return Tiles.RED_NODE
		'green':
			return Tiles.GREEN_NODE
		_:
			return -1

func rewire_crates():
	$wires.clear_layer()
	$nodes.clear_layer()
	
	# reset crate tiles
	for cell in main.get_used_cells():
		if main.has_tile_at_cell(Tiles.CRATE_WIRED, cell):
			main.replace_tile_at_cell(Tiles.CRATE_WIRED, Tiles.CRATE, cell)
	
	# update gates
	for gate in gates.entities:
		var wire_groups = collect_wire_groups(gate)
		
		# udpate wired crates and add wires
		for group in wire_groups:
			var wire_tile = get_wire_tile(group.color)
			var node_tile = get_node_tile(group.color)
			
			for cell in group.cells:
				if targets.has_tile_at_cell(Tiles.TARGET, cell):
					$nodes.stack_tile_at_cell(node_tile, cell)
				if targets.has_tile_at_cell(Tiles.ANTITARGET, cell):
					$nodes.stack_tile_at_cell(Tiles.ANTITARGET, cell)
				for dir in Directions.ALL_DIRS:
					var neighbor = Directions.shift_cell(cell, dir)
					if group.cells.has(neighbor):
						$wires.stack_tile_at_cell(wire_tile, cell, dir)
				if main.has_tile_at_cell(Tiles.CRATE, cell):
					main.replace_tile_at_cell(Tiles.CRATE, Tiles.CRATE_WIRED, cell)
		
		# open/close gate
		if gate.is_open:
			if main.has_tile_at_cell(Tiles.GATE, gate.cell):
				main.remove_tile_from_cell(Tiles.GATE, gate.cell)
		else:
			if not main.has_tile_at_cell(Tiles.GATE, gate.cell):
				main.stack_tile_at_cell(Tiles.GATE, gate.cell)

func collect_wire_groups(gate):
	var groups = []
	
	var seeds = []
	
	for cell in gate.points:
		if targets.has_tile_at_cell(Tiles.TARGET, cell):
			if any_crate_exists_at(main, cell):
				seeds.append(cell)
	
	for seed_cell in seeds:
		if get_group_with_cell(groups, seed_cell) != null:
			continue
		var group = {cells=[], color='yellow'}
		groups.append(group)
		var to_spread_to = [seed_cell]
		while to_spread_to.size() > 0:
			var cell = to_spread_to.pop_back()
			
			group.cells.append(cell)
			
			if targets.has_tile_at_cell(Tiles.ANTITARGET, cell):
				group.color = 'red'
				
			for dir in Directions.ALL_DIRS:
				var neighbor = Directions.shift_cell(cell, dir)
				if any_crate_exists_at(main, neighbor):
					if not group.cells.has(neighbor):
						to_spread_to.append(neighbor)
	
	gate.is_open = false
	if groups.size() == 1 and not groups[0].color == 'red' and all_points_are_in_group(gate.points, groups[0]):
		groups[0].color = 'green'
		gate.is_open = true
	
	return groups


func all_points_are_in_group(points, group):
	for point in points:
		if not group.cells.has(point):
			return false
	return true

func get_group_with_cell(groups, cell):
	for group in groups:
		if group.cells.has(cell):
			return group
	return null

func group_connected_wires(wired_cells):
	return [wired_cells]
