extends Node3D

@export var tooth_material: Material
@export var plate_material: Material

const TOOTH_CLOSED = 55.0

@onready var maw: Node3D = $Maw
var tooth_sockets: Array[Node3D] = []

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	build_teeth(rng)
	build_plates(rng)

func build_teeth(rng: RandomNumberGenerator) -> void:
	var tooth_mesh = CylinderMesh.new()
	tooth_mesh.bottom_radius = 0.07
	tooth_mesh.height = 0.5
	tooth_mesh.radial_segments = 5
	for ring in 2:
		var n = 18 if ring == 0 else 12
		var r = 0.85 if ring == 0 else 0.55
		for i in n:
			var a = TAU * i / n + ring * 0.2 + rng.randf_range(-0.05, 0.05)
			var socket = Node3D.new()
			maw.add_child(socket)
			socket.position = Vector3(cos(a) * r, 0.15 - ring * 0.03, sin(a) * r)
			socket.rotation = Vector3(0.0, -a, deg_to_rad(TOOTH_CLOSED))
			var tooth = MeshInstance3D.new()
			tooth.mesh = tooth_mesh
			tooth.material_override = tooth_material
			socket.add_child(tooth)
			tooth.position.y = 0.25
			tooth.scale = Vector3.ONE * rng.randf_range(0.75, 1.25)
			tooth_sockets.append(socket)

func build_plates(rng: RandomNumberGenerator) -> void:
	var plate_mesh = SphereMesh.new()
	plate_mesh.radius = 0.5
	plate_mesh.height = 1.0
	for i in 7:
		var a = TAU * i / 7 + 0.3
		var plate = MeshInstance3D.new()
		plate.mesh = plate.mesh
		plate.material_override = plate_material
		maw.add_child(plate)
		plate.position = Vector3(cos(a) * 1.1, -0.55, sin(a) * 1.1)
		plate.rotation = Vector3(0.0, -a, deg_to_rad(20))
		plate.scale = Vector3(0.7, 0.45, 0.55) * rng.randf_range(0.85, 1.15)
