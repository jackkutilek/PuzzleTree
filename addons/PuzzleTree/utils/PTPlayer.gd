extends Node2D
class_name PTPlayer, "../icons/PTPlayer.png"

const Inputs = preload("inputs.gd") 
const Directions = preload("directions.gd") 

export var PlayerTile = 0
export (String) var PlayerLayer = ""
export (String) var ExtraCollisionLayers = ""

# --------------------------------------------------------------------------------------------------

var extra_layers = []

func _ready():
	if ExtraCollisionLayers != "":
		var split_layers = ExtraCollisionLayers.split(',')
		for split_layer in split_layers:
			var layer = get_node("%"+split_layer)
			if layer != null:
				extra_layers.append(layer)

# Called once when the game starts
func init_update(context):
	var layer = get_node("%" + PlayerLayer)
	if layer == null:
		return
	store_player_position(context, layer)

# Called once during each each turn
func frame_update(context):
	var layer = get_node("%" + PlayerLayer)
	if layer == null:
		return
	
	var pressed = Inputs.is_pressed_key(context.frame_key)
	var key_dir = Inputs.get_key_dir(context.frame_key)
	if pressed:
		var movement := get_node("%PTMovement") as PTMovement
		if movement != null:
			movement.queue_move(layer, context.player_pos, key_dir, extra_layers)

# Called at the end of each turn
func late_frame_update(context):
	var layer = get_node("%" + PlayerLayer)
	if layer == null:
		return
	store_player_position(context, layer)

func store_player_position(context: Dictionary, layer: PTTiles):
	for cell in layer.get_used_cells():
		if layer.has_tile_at_cell(PlayerTile, cell):
			context.player_pos = cell
			context.camera_pos = context.player_pos
