extends Camera3D
var shake_amount = 0.0
var base_position = Vector3.ZERO

func _ready() -> void:
	base_position = position

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
	shake_amount = amount
