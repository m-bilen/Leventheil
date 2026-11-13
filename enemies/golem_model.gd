extends Node3D

@export var tooth_material: Material
@export var plate_material: Material

const FlashMaterial = preload("res://enemies/flash_material.tres")
const TOOTH_CLOSED = 55.0
const WALK_SPEED = 5.0
const WALK_SWING = 0.25
const WALK_BOB = 0.06
@onready var rig: Node3D = $Rig
@onready var arms: Array[Node3D] = [$Rig/ArmR, $Rig/ArmL]
@onready var legs: Array[Node3D] = [$LegR, $LegL]
var core_material: StandardMaterial3D
var moving = false
var walk_time = 0.0
var arm_rest: Array[float] = []
var leg_rest: Array[float] = []
var rig_base_y = 0.0
var tooth_angle = deg_to_rad(TOOTH_CLOSED)
var target_pitch = 0.0
var target_arm = 0.0
var target_tooth = TOOTH_CLOSED
var target_glow = 2.0
var pose_speed = 5.0
@onready var eye: MeshInstance3D = $Rig/Eye
@onready var root_vines: Node3D = $RootVines
var eye_material : StandardMaterial3D
var parts: Array[Node] = []
 


@onready var maw: Node3D = $Rig/Maw
var tooth_sockets: Array[Node3D] = []

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	build_teeth(rng)
	build_plates(rng)
	eye_material = eye.material_override.duplicate()
	eye.material_override = eye_material
	parts = find_children( "*", "MeshInstance3D", true, false)
	var core: MeshInstance3D = $Rig/Maw/Core
	core_material = core.material_override.duplicate()
	core.material_override = core_material
	rig_base_y = rig.position.y
	for arm in arms:
		arm_rest.append(arm.rotation.x)
	for leg in legs: 
		leg_rest.append(leg.rotation.x)


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

func get_base_color() -> Color:
	return eye_material.emission

func set_color(color: Color) -> void:
	eye_material.albedo_color = color
	eye_material.emission = color 

func set_flash(on: bool) -> void:
	var overlay = FlashMaterial if on else null
	for part in parts:
		part.material_overlay = overlay

func set_rooted(on: bool) -> void:
	root_vines.visible = on

func set_moving(on: bool) -> void:
	moving = on

func pose_idle() -> void:
	set_targets(0.0, 0.0, TOOTH_CLOSED, 2.0, 5.0)

func pose_windup() -> void:
	set_targets(-0.55, -1.0, -10.0, 6.0, 6.0)

func pose_strike() -> void:
	set_targets(0.2, 0.15, 70.0, 9.0, 12.0)

func pose_recover() -> void:
	set_targets(0.1, 0.2, 40.0, 1.0, 3.0)

func pose_stunned() -> void:
	set_targets(0.3, 0.5, 25.0, 0.3, 4.0)

func set_targets(pitch: float, arm: float, tooth: float, glow: float, speed: float) -> void:
	target_pitch = pitch
	target_arm = arm
	target_tooth = tooth
	target_glow = glow
	pose_speed = speed

func _process(delta: float) -> void:
	var blend = min(pose_speed * delta, 1.0)
	var swing = 0.0
	if moving:
		walk_time += delta * WALK_SPEED
		swing = sin(walk_time) * WALK_SWING
	rig.rotation.x = lerp(rig.rotation.x, target_pitch, blend)
	rig.position.y = rig_base_y + (abs(sin(walk_time)) * WALK_BOB if moving else 0.0)
	for i in arms.size():
		var side = 1.0 if i == 0 else -1.0
		arms[i].rotation.x = lerp(arms[i].rotation.x, arm_rest[i] + target_arm + swing * side, blend)
	for i in legs.size():
		var side = 1.0 if i == 0 else -1.0
		legs[i].rotation.x = lerp(legs[i].rotation.x, leg_rest[i] - swing * side, blend)
	tooth_angle = lerp(tooth_angle, deg_to_rad(target_tooth), blend)
	for socket in tooth_sockets:
		socket.rotation.z = tooth_angle
	core_material.emission_energy_multiplier = lerp(core_material.emission_energy_multiplier, target_glow, blend)
