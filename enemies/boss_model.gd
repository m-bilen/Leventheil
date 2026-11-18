extends "res://enemies/golem_model.gd"

const CROWN_COUNT = 8
const CROWN_RADIUS = 1.0
const RAGE_GLOW = 3.0

@export var crown_material: StandardMaterial3D

func _ready() -> void:
	crown_material = crown_material.duplicate()
	build_crown()
	super()
	set_rage(0.0)

func build_crown() -> void:
	var thorn = CylinderMesh.new()
	thorn.top_radius = 0.0
	thorn.bottom_radius = 0.14
	thorn.height = 1.2
	thorn.radial_segments = 6
	for i in CROWN_COUNT:
		var a = TAU * i / CROWN_COUNT
		var socket = Node3D.new()
		maw.add_child(socket)
		socket.position = Vector3(cos(a) * CROWN_RADIUS, 0.2, sin(a) * CROWN_RADIUS)
		socket.rotation = Vector3(0.0, -a, deg_to_rad(-25.0))
		var spike = MeshInstance3D.new()
		spike.mesh = thorn
		spike.material_override = crown_material
		socket.add_child(spike)
		spike.position.y = 0.6
		spike.scale = Vector3.ONE * (1.0 + 0.3 * sin(a * 3.0))

func set_rage(t: float) -> void:
	crown_material.emission_energy_multiplier = lerp(0.0, RAGE_GLOW, t)
