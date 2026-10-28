extends MeshInstance3D
const FLY_SPEED = 20.0
const MAX_RANGE = 10.0
var travelled = 0.0
var is_flying = false
var fly_direction = Vector3.ZERO
func launch(direction: Vector3)-> void:
	is_flying = true
	fly_direction = direction
func _process(delta:float) -> void:
	if not is_flying:
		return
	var step = FLY_SPEED * delta
	position += fly_direction * step 
	travelled += step
	if travelled >= MAX_RANGE:
		plant()
func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
func _on_body_entered(body :Node3D) -> void:
	if not is_flying:
		return 
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
func plant() -> void:
	is_flying = false
	position.y = 0.3
	rotation = Vector3(PI, 0, 0)
	add_to_group("seeds")
	Events.wave_started.connect(_on_wave_started)
func _on_wave_started(_number: int) -> void:
	queue_free()
