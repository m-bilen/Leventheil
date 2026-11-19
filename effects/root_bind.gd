extends Node3D

const GROW_TIME = 0.15
const HIDDEN_SCALE = Vector3(1.0, 0.01, 1.0)

@export var radius: float = 0.5
@export var height: float = 1.0
@export var root_count: int = 6
@export var material: Material

var tween: Tween


func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in root_count:
		var a = TAU * i / root_count + rng.randf_range(-0.3, 0.3)
		var outward = Vector3(cos(a), 0.0, sin(a))
		var tangent = Vector3(-sin(a), 0.0, cos(a))
		var start = outward * radius * 1.4
		var dir = (-outward + Vector3.UP * 1.3 + tangent * 0.5).normalized()
		var length = height * rng.randf_range(0.9, 1.3)
		var thickness = rng.randf_range(0.04, 0.07) * radius / 0.5
		var mesh = VineBuilder.build(length, rng.randf_range(-0.2, 0.2) * length, thickness, 0.1, 0.03 * length, rng.randf() * TAU)
		VineBuilder.append_oriented(st, mesh, start, dir, length)
	var roots = MeshInstance3D.new()
	roots.mesh = st.commit()
	roots.material_override = material
	add_child(roots)
	visible = false
	scale = HIDDEN_SCALE 

func bind(on: bool) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	if on:
		visible = true
		tween.tween_property(self, "scale", Vector3.ONE, GROW_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(self, "scale", HIDDEN_SCALE, GROW_TIME)
		tween.tween_callback(hide)
