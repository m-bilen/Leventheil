extends Camera3D
var base_fov = 75.0
var shake_amount = 0.0
var base_position = Vector3.ZERO

func _ready() -> void:
	base_position = position
	base_fov = fov
	Events.camera_shake_requested.connect(shake)
	Events.camera_focus_requested.connect(focus_zoom)

func _process(delta: float) -> void:
	if shake_amount <= 0.0:
		position = base_position
		return
	
	shake_amount -= delta * 5.0
	position = base_position + Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		0.0
	) * shake_amount

func shake(amount: float) -> void:
	shake_amount = max(shake_amount,amount)

func focus_zoom(duration: float) -> void:
	fov = base_fov -25.0
	await get_tree().create_timer(duration, true, false, true).timeout
	fov = base_fov
