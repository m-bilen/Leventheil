extends Area3D

@export var delay: float = 0.8
@export var radius: float = 1.8
@export var damage: int = 1

var warning_material : ShaderMaterial
var timer = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	timer = delay
	var plane: PlaneMesh = mesh.mesh.duplicate()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	mesh.mesh = plane
	warning_material = mesh.material_override.duplicate()
	mesh.material_override = warning_material

func _physics_process(delta: float) -> void:
	timer -= delta
	warning_material.set_shader_parameter("progress", 1.0 - timer / delay)
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
