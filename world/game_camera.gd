extends Camera3D
@export var target: Node3D
const FOLLOW_SPEED = 5.0
const FOCUS_FOV_DROP = 25.0

var base_fov = 75.0
var shake_amount = 0.0
var offset = Vector3.ZERO
var follow_position = Vector3.ZERO
var focus_point = Vector3.ZERO
var is_focusing = false

func _ready() -> void:
	base_fov = fov
	offset = global_position - target.global_position
	follow_position = global_position
	Events.camera_shake_requested.connect(shake)
	Events.camera_focus_requested.connect(focus_zoom)

func _process(delta: float) -> void:
	var anchor = focus_point if is_focusing else target.global_position
	var step = delta
	if is_focusing:
		step = delta / Engine.time_scale
	follow_position = follow_position.lerp(anchor + offset, FOLLOW_SPEED * step)

	var shake_offset = Vector3.ZERO
	if shake_amount > 0.0:
		shake_amount -= delta * 5.0
		shake_offset = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * shake_amount
	global_position = follow_position + shake_offset

func shake(amount: float) -> void:
	shake_amount = max(shake_amount,amount)

func focus_zoom(point: Vector3, duration: float) -> void:
	focus_point = point
	is_focusing = true
	fov = base_fov - FOCUS_FOV_DROP
	await get_tree().create_timer(duration, true, false, true).timeout
	is_focusing = false
	fov = base_fov
