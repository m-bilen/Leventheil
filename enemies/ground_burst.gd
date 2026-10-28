extends Area3D

const DELAY = 0.8
const DAMAGE = 1

var timer = DELAY

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	Events.wave_started.connect(_on_wave_started)

func _physics_process(delta: float) -> void:
	timer -= delta
	mesh.transparency = lerp(0.85, 0.1, 1.0 - timer / DELAY)
	if timer <= 0.0:
		erupt()

func erupt() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("take_damage") and body.is_on_floor():
			body.take_damage(DAMAGE)
	Events.camera_shake_requested.emit(0.2)
	queue_free()

func _on_wave_started(_number: int) -> void:
	queue_free()
