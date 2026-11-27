extends EnemyModel

@export var tooth_material: Material
@export var plate_material: Material

const TOOTH_CLOSED = 55.0
const WALK_SPEED = 5.0
const WALK_SWING = 0.25
const WALK_BOB = 0.06
@onready var rig: Node3D = $Rig
@onready var arms: Array[Node3D] = [$Rig/ArmR, $Rig/ArmL]
@onready var legs: Array[Node3D] = [$LegR, $LegL]
var core_material: StandardMaterial3D
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
 


@onready var maw: Node3D = $Rig/Maw
var tooth_sockets: Array[Node3D] = []

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	organicize(rng)
	build_teeth(rng)
	build_plates(rng)
	super()
	var core: MeshInstance3D = $Rig/Maw/Core
	core_material = core.material_override.duplicate()
	core.material_override = core_material
	rig_base_y = rig.position.y
	for arm in arms:
		arm_rest.append(arm.rotation.x)
	for leg in legs: 
		leg_rest.append(leg.rotation.x)
	walk_time = randf() * TAU


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

func _on_pose_changed(new_pose: Pose) -> void:
	match new_pose:
		Pose.IDLE:
			set_targets(0.0, 0.0, TOOTH_CLOSED, 2.0, 5.0)
		Pose.WINDUP:
			set_targets(-0.55, -1.0, 45.0, 3.0, 6.0 )
		Pose.OPEN:
			set_targets(target_pitch, target_arm, -10.0, 8.0, 18.0)
		Pose.SLAM:
			set_targets(-0.4, -2.2, 60.0, 1.0, 5.0)
		Pose.STRIKE:
			set_targets(0.2, 0.15, 70.0, 9.0, 12.0)
		Pose.RECOVER:
			set_targets(0.0, 0.2, 40.0, 1.0, 3.0)
		Pose.STUNNED:
			set_targets(0.3, 0.5, 25.0, 0.3, 4.0,)
		Pose.PUSH:
			set_targets(-0.1, 0.7, TOOTH_CLOSED, 2.0, 12.0)
		Pose.SHOVE:
			set_targets(-0.1, -0.9, TOOTH_CLOSED, 2.0, 20.0)
		Pose.CROUCH:
			set_targets(0.35, -0.4, 75.0, 4.0, 25.0)
		Pose.LUNGE:
			set_targets(0.1, 0.6, -10.0, 8.0, 18.0)

func organicize(rng: RandomNumberGenerator) -> void:
	var noise = FastNoiseLite.new()
	noise.seed = 4
	noise.frequency = 1.1
	var body :  MeshInstance3D = $Rig/Body
	var sphere: SphereMesh = body.mesh.duplicate()
	sphere.radial_segments = 40
	sphere.rings = 20
	body.mesh = lumpy(sphere, noise, 0.22)
	var collar: MeshInstance3D = $Rig/Maw/Collar
	var tube: CylinderMesh = collar.mesh.duplicate()
	tube.radial_segments = 28
	tube.rings = 6
	collar.mesh = lumpy(tube, noise, 0.08)
	for pivot in [$Rig/ArmR, $Rig/ArmL]:
		replace_limb(pivot.get_node("Mesh"), 1.6, 0.36, 0.5, rng)
	for pivot in [$LegR, $LegL]:
		replace_limb(pivot.get_node("Mesh"), 1.0, 0.24, 0.6, rng)
	add_twigs(rng)

func lumpy(src: PrimitiveMesh, noise: FastNoiseLite, amount: float) -> ArrayMesh:
	var arrays = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in verts.size():
		verts[i] += normals[i] * noise.get_noise_3dv(verts[i]) * amount
	arrays[Mesh.ARRAY_VERTEX] = verts
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st = SurfaceTool.new()
	st.create_from(am, 0)
	st.generate_normals()
	return st.commit()

func replace_limb(mesh_node: MeshInstance3D, length: float, thickness: float, taper: float, rng: RandomNumberGenerator) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var limb = VineBuilder.build(length, rng.randf_range(-0.12, 0.12), thickness, taper, 0.05, rng.randf() * TAU)
	VineBuilder.append_oriented(st, limb, Vector3(0, length * 0.5 - 0.05, 0), Vector3.DOWN, length)
	mesh_node.mesh = st.commit()

func add_twigs(rng: RandomNumberGenerator) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var a = rng.randf_range(-1.2, 1.2)
		var start = Vector3(sin(a) * 0.9, 0.85 + rng.randf_range(-0.1, 0.2), -0.3 + cos(a) * 0.2)
		var dir = Vector3(sin(a) * 0.6, 1.0, rng.randf_range(-0.8, -0.2)).normalized()
		var length = rng.randf_range(0.5, 0.9)
		var twig = VineBuilder.build(length, rng.randf_range(-0.15, 0.15), 0.05, 0.15, 0.05, rng.randf() * TAU)
		VineBuilder.append_oriented(st, twig, start, dir, length)
	var twigs = MeshInstance3D.new()
	twigs.mesh = st.commit()
	twigs.material_override = $Rig/Body.material_override
	$Rig.add_child(twigs)

func get_head_point() -> Vector3:
	return maw.global_position

func set_color(color: Color) -> void:
	super(color)
	core_material.albedo_color = color
	core_material.emission = color
