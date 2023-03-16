@icon("../icons/PTCamera.png")
extends Camera2D
class_name PTCamera

@export var tile_size = 5
@export_enum("auto", "scripted") var mode:String = "auto"

@export var target_size = Vector2(10,10)
@export var eased_follow = false
@export var camera_speed = 1
@export var snap_size: Vector2 = Vector2(0,0)

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
			
			zoom = get_target_zoom()

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
			var z = get_target_zoom()
			var zdiff = z - zoom
			zoom += zdiff*camera_speed*delta
			
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
	noise = FastNoiseLite.new()
	noise.seed = randi()%2000
	noise.frequency = 1/4.0
	noise.fractal_octaves = 2

# --------------------------------------------------------------------------------------------------

func update_target(context):
	if context.has("camera_pos"):
		var camera_pos = context.camera_pos
		if camera_pos != null:
			if snap_size.x > 0:
				camera_pos = Vector2(floor(camera_pos.x/snap_size.x)*snap_size.x + snap_size.x/2, floor(camera_pos.y/snap_size.y)*snap_size.y + snap_size.y/2)
			target = camera_pos * tile_size
	
	if context.has("camera_size"):
		var camera_size = context.camera_size
		if camera_size != null:
			target_size = camera_size

func update_level_size(context):
	if not context.has("_level_width"):
		print("camera error: switch camera settings or change ldtk layout")
		return
	
	var width = context._level_width * tile_size
	var height = context._level_height * tile_size
	level_size = Vector2(width, height)

func get_target_zoom():
	var size = get_viewport().get_visible_rect().size
	var zoomx = size.x / (target_size.x * tile_size)
	var zoomy = size.y / (target_size.y * tile_size)
	var z = min(zoomx, zoomy)
	return Vector2(z,z)

func fit_to_level():
	var size = get_viewport().get_visible_rect().size
	var zoomx = level_size.x / size.x
	var zoomy = level_size.y / size.y
	var z = max(zoomx, zoomy)
	zoom = Vector2(1/z,1/z)
	follow_offset = Vector2(level_size.x/2, level_size.y/2)

# ----------------------------------------------------------------------------------------------
@export_category("Screen Shake")
@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

var noise: FastNoiseLite
var noise_y = 0
var shake_offset = Vector2(0,0)

func shake(amount):
	trauma = amount
	noise_y = 0

func _shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	var a = noise.get_noise_2d(noise.seed, noise_y)
	var b = noise.get_noise_2d(noise.seed*2, noise_y)
	var c = noise.get_noise_2d(noise.seed*3, noise_y)
	rotation = max_roll * amount * a
	shake_offset.x = max_offset.x * amount * b
	shake_offset.y = max_offset.y * amount * c
	pass
