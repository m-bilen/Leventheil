extends Area3D

@export var delay: float = 0.8
@export var radius: float = 1.8
@export var damage: int = 1

var timer = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	timer = delay
	var shape: CylinderShape3D = $CollisionShape3D.shape.duplicate()
	shape.radius = radius
	$CollisionShape3D.shape = shape
	var cylinder: CylinderMesh = mesh.mesh.duplicate()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	mesh.mesh = cylinder
	Events.wave_started.connect(_on_wave_started)

func _physics_process(delta: float) -> void:
	timer -= delta
	mesh.transparency = lerp(0.85, 0.1, 1.0 - timer / delay)
	if timer <= 0.0:
		erupt()

func erupt() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			continue
		if body.has_method("take_damage") and body.is_on_floor():
			body.take_damage(damage)
	Events.camera_shake_requested.emit(0.2)
	queue_free()

func _on_wave_started(_number: int) -> void:
	queue_free()
