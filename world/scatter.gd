extends MultiMeshInstance3D

@export var source_mesh: Mesh
@export var count: int = 40
@export var min_radius: float = 4.0
@export var max_radius: float = 22.0
@export var min_scale: float = 0.6
@export var max_scale: float = 1.4
@export var height_scale: float = 1.0
@export var max_tilt: float = 0.2
@export var y_offset: float = 0.25
@export var scatter_seed: float = 1
@export var irregularity: float = 0.0
@export_group("Clustering")
@export var cluster_count: int = 0
@export var clustered_ratio: float = 0.7
@export var cluster_min_radius: float = 15.0
@export var cluster_max_radius: float = 21.0
@export var cluster_spread: float = 1.5
func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = source_mesh
	mm.instance_count = count
	var centers: Array[Vector3] = []
	for c in cluster_count:
		var ca = rng.randf() * TAU
		var cd = rng.randf_range(cluster_min_radius, cluster_max_radius)
		centers.append(Vector3(cos(ca) * cd, 0.0, sin(ca) * cd))
	for i in count:
		var pos: Vector3
		if not centers.is_empty() and rng.randf() < clustered_ratio:
			var center = centers[rng.randi() % centers.size()]
			pos = center + Vector3(rng.randfn(0.0, cluster_spread), 0.0, rng.randfn(0.0, cluster_spread))
		else:
			var angle = rng.randf() * TAU
			var dist = sqrt(rng.randf_range(min_radius * min_radius, max_radius * max_radius))
			pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		pos.y = y_offset

		var s = rng.randf_range(min_scale, max_scale)
		var sx = s * rng.randf_range(1.0 - irregularity, 1.0 + irregularity)
		var sz = s * rng.randf_range(1.0 - irregularity, 1.0 + irregularity)
		var b = Basis(Vector3.UP, rng.randf() * TAU)
		b = b.rotated(Vector3.RIGHT, rng.randf_range(-max_tilt, max_tilt))
		b = b.scaled(Vector3(sx, s * height_scale, sz))
		mm.set_instance_transform(i, Transform3D(b, pos))
		mm.set_instance_transform(i, Transform3D(b, pos))
	multimesh = mm
