extends MeshInstance3D
signal hit_enemy
const FLY_SPEED = 20.0
const LIFETIME = 3.0
var is_flying = false
var fly_direction = Vector3.ZERO
var life_timer = 0.0
var is_damaging = false
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
	if body.name == "Player" :
		return
	if not is_flying and not is_damaging :
		return 
	print("carptim: ", body.name, " | flying: ", is_flying, " | damaging: ", is_damaging)
	if body.has_method("take_damage"):
		body.take_damage(1)
		if is_flying:
			queue_free()
		else:
			hit_enemy.emit()
func set_damaging(value: bool) -> void:
	is_damaging = value
