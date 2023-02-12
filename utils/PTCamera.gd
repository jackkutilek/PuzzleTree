extends Camera2D
class_name PTCamera, "../icons/PTCamera.png"

export var tile_size = 5
export(String, "auto", "scripted") var mode = "auto"

export var target_size = 100
export var eased_follow = false
export var camera_speed = 1
export(float) var snap_size = 0.0

var level_size = Vector2(1,1)
var target = Vector2(0,0)

# --------------------------------------------------------------------------------------------------

func late_init_update(context):
	match mode:
		"auto":
			update_level_size(context)
		"scripted":
			update_target(context)
			offset = target

func late_frame_update(context):
	match mode:
		"auto":
			update_level_size(context)
		"scripted":
			update_target(context)

func late_reset_update(context):
	match mode:
		"auto":
			update_level_size(context)
		"scripted":
			update_target(context)

# --------------------------------------------------------------------------------------------------

func _process(delta):
	match mode:
		"auto":
			fit_to_level()
		"scripted":
			var size = get_viewport().size
			var zoomx = target_size / size.x
			var zoomy = target_size / size.y
			var z = max(zoomx, zoomy)
			zoom = Vector2(z,z)
			var diff = target - offset
			if eased_follow:
				offset = offset + diff*camera_speed*delta
			else:
				offset = target

# --------------------------------------------------------------------------------------------------

func update_target(context):
	if context.has("camera_pos"):
		var camera_pos = context.camera_pos
		if camera_pos == null:
			return
		if snap_size > 0:
			camera_pos = Vector2(floor(camera_pos.x/snap_size)*snap_size + snap_size/2, floor(camera_pos.y/snap_size)*snap_size + snap_size/2)
		target = camera_pos * tile_size
		if snap_size > 0:
			target_size = snap_size*tile_size

func update_level_size(context):
	if not context.has("_level_width"):
		print("camera error: switch camera settings or change ldtk layout")
		return
	
	var width = context._level_width * tile_size
	var height = context._level_height * tile_size
	level_size = Vector2(width, height)

func fit_to_level():	
	var size = get_viewport().size
	var zoomx = level_size.x / size.x
	var zoomy = level_size.y / size.y
	var z = max(zoomx, zoomy)
	zoom = Vector2(z,z)
	offset = Vector2(level_size.x/2, level_size.y/2)
