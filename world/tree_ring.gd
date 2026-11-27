extends Node3D

const TreeScene = preload("res://world/tree_trunk.tscn")

@export var  count: int = 14
@export var radius: float = 21.0
@export var jitter: float = 1.5
@export var min_scale: float = 0.8
@export var max_scale: float = 1.4
@export var vine_material: Material
@export var vines_per_gap: int = 5
@export var stem_count: int  = 700
@export_range(0.0, 1.0) var foreground_shade: float = 0.5

var trees: Array[Node3D] = []
var stump_material: Material
var stump_moss: Material

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		var angle = TAU / count * i + rng.randf_range(-0.15, 0.15)
		var dist = radius + rng.randf_range(-jitter, jitter)
		var tree = TreeScene.instantiate()
		add_child(tree)
		trees.append(tree)
		tree.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		tree.rotation.y = rng.randf() * TAU
		var s = rng.randf_range(min_scale, max_scale)
		var height = 1.0 + rng.randf_range(0.0, 0.3)
		if tree.position.z > radius * 0.35:
			height = 0.07
			shade_stump(tree.get_node("MeshInstance3D"))
		tree.scale = Vector3(s, height, s)
	spawn_vines(rng)

func spawn_vines(rng: RandomNumberGenerator) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low_st = SurfaceTool.new()
	low_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for n in stem_count:
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(radius - 2.5, radius + 6.0)
		var base = Vector3(cos(angle) * dist, -0.1, sin(angle) * dist)
		var low = base.z > radius * 0.35
		if low:
			add_stem(low_st, rng, base, rng.randf_range(0.6, 1.5), rng.randf_range(0.03, 0.07), rng.randf_range(0.2, 0.7))
			continue
		var length = rng.randf_range(3.0, 9.0)
		var thickness = rng.randf_range(0.06, 0.16)
		add_stem(st, rng, base, length, thickness, rng.randf_range(0.2, 1.2))
		for c in rng.randi_range(1, 3):
			var along = rng.randf_range(0.3, 0.7)
			var child_base = base + Vector3.UP * length * along * 0.8
			add_stem(st, rng, child_base, length * rng.randf_range(0.3, 0.6), thickness * (1.0 - 0.85 * along), rng.randf_range(0.6, 1.4))
	var thicket = MeshInstance3D.new()
	thicket.mesh = st.commit()
	thicket.material_override = vine_material
	add_child(thicket)
	var undergrowth = MeshInstance3D.new()
	undergrowth.mesh = low_st.commit()
	undergrowth.material_override = darken(vine_material)
	add_child(undergrowth)

func add_stem(st: SurfaceTool, rng: RandomNumberGenerator, base: Vector3, length: float, thickness: float, lean: float) -> void:
	var yaw = rng.randf() * TAU
	var lean_dir = Vector3(cos(yaw), 0.0, -sin(yaw))
	var inward = lean_dir.dot(-base.normalized())
	if inward > 0.0:
		lean *= 1.0 - inward * 0.8
	var stem_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI / 2.0 - lean)
	var bend = rng.randf_range(-0.25, 0.25) * length
	var stem = VineBuilder.build(length, bend, thickness, 0.12, 0.06 * length, rng.randf() * TAU)
	st.append_from(stem, 0, Transform3D(stem_basis, base + stem_basis.x * length / 2.0))

func shade_stump(mesh: MeshInstance3D) -> void:
	if stump_material == null:
		stump_material = darken(mesh.material_override)
		stump_moss = mesh.material_overlay.duplicate()
		stump_moss.set_shader_parameter("moss_color", stump_moss.get_shader_parameter("moss_color") * foreground_shade)
	mesh.material_override = stump_material
	mesh.material_overlay = stump_moss

func darken(material: StandardMaterial3D) -> StandardMaterial3D:
	var dark = material.duplicate()
	dark.albedo_color = Color(dark.albedo_color * foreground_shade, dark.albedo_color.a)
	return dark
