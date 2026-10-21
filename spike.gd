extends MeshInstance3D
const FLY_SPEED = 20.0
const LIFETIME = 3.0
var is_flying = false
var fly_direction = Vector3.ZERO
var life_timer = 0.0
func launch(direction: Vector3)-> void:
	is_flying = true
	fly_direction = direction
	life_timer = LIFETIME
func _process(delta:float) -> void:
	if not is_flying:
		return
	position += fly_direction * FLY_SPEED * delta
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()
func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
func _on_body_entered(body :Node3D) -> void:
	if not is_flying:
		return 
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
