extends Area3D

const SPEED = 9.0
const MAX_RANGE = 16.0
const DAMAGE = 1

var direction = Vector3.ZERO
var travelled = 0.0
var has_hit = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	Events.wave_started.connect(_on_wave_started)

func launch(dir: Vector3) -> void:
	direction = dir
	look_at(global_position + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	var step = SPEED * delta
	global_position += direction * step
	travelled += step
	if travelled >= MAX_RANGE:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if has_hit or not body.has_method("take_damage"):
		return
	if body.is_on_floor():
		has_hit = true
		body.take_damage(DAMAGE)

func _on_wave_started(_number: int) -> void:
	queue_free()
