extends Node2D

onready var gates = get_node("%Gates")

func init_update(context):
	context.miny = 0

# Called at the end of each turn
func late_frame_update(context):	
	var in_bottom_row = int(context.player_pos.y)%11 == -1
	if in_bottom_row and context.player_pos.y < context.miny:
		context.miny = context.player_pos.y
		context.checkpoint = true
