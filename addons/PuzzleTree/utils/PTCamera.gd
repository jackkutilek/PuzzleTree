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
var follow_offset = Vector2(0,0)

# --------------------------------------------------------------------------------------------------

func late_init_update(context):
	match mode:
		"auto":
			update_level_size(context)
		"scripted":
			update_target(context)
			follow_offset = target
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
			var diff = target - follow_offset
			if eased_follow:
				follow_offset = follow_offset + diff*camera_speed*delta
			else:
				follow_offset = target
	
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		_shake()
	offset = follow_offset + shake_offset

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

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
	follow_offset = Vector2(level_size.x/2, level_size.y/2)

# ----------------------------------------------------------------------------------------------

export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

onready var noise = OpenSimplexNoise.new()
var noise_y = 0
var shake_offset = Vector2(0,0)

func shake(amount):
	print("shake ", amount)
	trauma = amount
	noise_y = 0

func _shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	shake_offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	shake_offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	pass
