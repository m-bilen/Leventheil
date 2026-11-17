extends EnemyModel

const ARM_LENGTH = 0.9
const ARM_THICKNESS = 0.06

@export var arm_material: Material

@onready var arm_pivots: Array[Node3D] = [$Body/ArmR, $Body/ArmL]

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in arm_pivots.size():
		var side = 1.0 if i == 0 else -1.0
		build_arm(arm_pivots[i], side, rng)
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
	var up = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var axis_z = dir.cross(up).normalized()
	var axis_y = axis_z.cross(dir)
	var branch_basis = Basis(dir, axis_y, axis_z)
	st.append_from(mesh, 0, Transform3D(branch_basis, start + dir * length / 2.0))
