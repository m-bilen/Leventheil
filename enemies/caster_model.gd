extends EnemyModel

const ARM_LENGTH = 0.9
const ARM_THICKNESS = 0.06
const POSE_SPEED = 6.0
const STRIKE_HOLD = 0.25
const STUN_HOLD = 0.6
const SWAY_SPEED = 1.5
const SWAY_AMOUNT = 0.05
const BOB_SPEED = 6.0
const BOB_HEIGHT = 0.05

@onready var body: Node3D = $Body
@onready var neck: Node3D = $Body/Neck
@onready var cap: Node3D = $Body/Neck/Cap
@onready var gills: MeshInstance3D = $Body/Neck/Cap/Gills

var gill_material: StandardMaterial3D
var neck_rest = 0.0
var cap_rest = 0.0
var arm_rest: Array[float] = []
var body_base_y = 0.0
var time = 0.0
var hold_timer = 0.0
var target_neck = 0.0
var target_cap = 0.0
var target_arm = 0.0
var target_glow = 0.6
var pose_speed = POSE_SPEED

@export var arm_material: Material

@onready var arm_pivots: Array[Node3D] = [$Body/ArmR, $Body/ArmL]

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in arm_pivots.size():
		var side = 1.0 if i == 0 else -1.0
		build_arm(arm_pivots[i], side, rng)
	gill_material = gills.material_override.duplicate()
	gills.material_override = gill_material
	neck_rest = neck.rotation.x
	cap_rest = cap.rotation.x 
	for pivot in arm_pivots:
		arm_rest.append(pivot.rotation.z)
	body_base_y = body.position.y
	super()

func build_arm(pivot: Node3D, side: float, rng: RandomNumberGenerator) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	add_branch(st, Vector3.ZERO, Vector3(side, 0.0, 0.0), ARM_LENGTH, ARM_THICKNESS, rng)
	for b in 2:
		var along = rng.randf_range(0.45, 0.75)
		var start = Vector3(side * ARM_LENGTH * along, 0.0, 0.0)
		var dir = Vector3(side, rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)).normalized()
		add_branch(st, start, dir, ARM_LENGTH * rng.randf_range(0.3, 0.45), ARM_THICKNESS * (1.0 - 0.85 * along), rng)
	var arm = MeshInstance3D.new()
	arm.mesh = st.commit()
	arm.material_override = arm_material
	pivot.add_child(arm)

func add_branch(st: SurfaceTool, start: Vector3, dir: Vector3, length: float, thickness: float, rng: RandomNumberGenerator) -> void:
	var bend = rng.randf_range(-0.15, 0.15) * length
	var mesh = VineBuilder.build(length, bend, thickness, 0.15, 0.04 * length, rng.randf() * TAU)
	VineBuilder.append_oriented(st, mesh, start, dir, length)

func _on_pose_changed(new_pose: Pose) -> void:
	hold_timer = 0.0
	match new_pose:
		Pose.WINDUP:
			set_targets(-0.45, -0.6, 1.3, 2.0, 5.0)
		Pose.STRIKE:
			set_targets(0.15, 0.1, 0.4, 4.0, 20.0)
		Pose.STUNNED:
			set_targets(0.4, 0.3, -0.3, 0.2, 8.0)
			hold_timer = STUN_HOLD
		_:
			set_targets(0.0, 0.0, 0.0, 0.6, POSE_SPEED)

func set_targets(neck_tilt: float, cap_tilt: float, arm: float, glow: float, speed:float) -> void:
	target_neck = neck_tilt 
	target_cap = cap_tilt
	target_arm = arm
	target_glow = glow
	pose_speed = speed

func _process(delta: float) -> void:
	time += delta
	if hold_timer > 0.0:
		hold_timer -= delta
		if hold_timer <= 0.0:
			set_pose(Pose.IDLE)
	var blend = min(pose_speed * delta, 1.0)
	neck.rotation.x = lerp(neck.rotation.x, neck_rest + target_neck, blend)
	cap.rotation.x = lerp(cap.rotation.x, cap_rest + target_cap, blend)
	for i in arm_pivots.size():
		var side = 1.0 if i == 0 else -1.0
		arm_pivots[i].rotation.z = lerp(arm_pivots[i].rotation.z, arm_rest[i] + target_arm * side, blend)
	gill_material.emission_energy_multiplier = lerp(gill_material.emission_energy_multiplier, target_glow, blend)
	body.rotation.z = sin(time * SWAY_SPEED) * SWAY_AMOUNT
	body.position.y = body_base_y + (abs(sin(time * BOB_SPEED)) * BOB_HEIGHT if moving else 0.0)
