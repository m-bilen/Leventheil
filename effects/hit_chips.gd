extends Node3D

const SHARD_POINTS = 5
const CORE_RATIO = 0.4

@export var shard_material: Material

var direction := Vector3.FORWARD
var color := Color.WHITE

@onready var chips: CPUParticles3D = $Chips
@onready var motes: CPUParticles3D = $Motes

static var shard_mesh: ArrayMesh


func _ready() -> void:
	if shard_mesh == null:
		shard_mesh = build_shard()
	chips.mesh = shard_mesh
	chips.material_override = shard_material
	var spray = (-direction * 0.4 + Vector3.UP).normalized()
	for p in [chips, motes]:
		p.direction = spray
		p.color = color
		p.emitting = true
	motes.finished.connect(queue_free)


static func build_shard() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: Array[Vector3] = []
	for i in SHARD_POINTS:
		var a = TAU * i / SHARD_POINTS + randf_range(-0.3, 0.3)
		var r = randf_range(0.6, 1.0) if i % 2 == 0 else randf_range(0.25, 0.45)
		outer.append(Vector3(cos(a) * r, sin(a) * r, 0.0) * 0.07)
	for i in SHARD_POINTS:
		var o1 = outer[i]
		var o2 = outer[(i + 1) % SHARD_POINTS]
		var c1 = o1 * CORE_RATIO
		var c2 = o2 * CORE_RATIO
		add_vertex(st, Vector3.ZERO, 0.0)
		add_vertex(st, c1, 0.0)
		add_vertex(st, c2, 0.0)
		add_vertex(st, c1, 0.0)
		add_vertex(st, o1, 1.0)
		add_vertex(st, o2, 1.0)
		add_vertex(st, c1, 0.0)
		add_vertex(st, o2, 1.0)
		add_vertex(st, c2, 0.0)
	return st.commit()


static func add_vertex(st: SurfaceTool, pos: Vector3, rim: float) -> void:
	st.set_uv(Vector2(rim, 0.0))
	st.add_vertex(pos)
