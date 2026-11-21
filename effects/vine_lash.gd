extends Node3D

const EXTEND_TIME = 0.08
const HOLD_TIME = 0.05
const RETRACT_TIME = 0.15

@export var material: Material

var target:= Vector3.ZERO

func _ready() -> void:
	var to_target = target - position
	var length = to_target.length()
	var dir = to_target / length
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vine = VineBuilder.build(length, randf_range(-0.6, 0.6), 0.07, 0.25, 0.25, randf() * TAU)
	VineBuilder.append_oriented(st, vine, Vector3.ZERO, dir, length)
	var side = dir.cross(Vector3.UP).normalized()
	for i in 2:
		var along = randf_range(0.3, 0.7)
		var flip = 1.0 if i == 0 else -1.0
		var twig_dir = (dir + side * flip * 0.8 + Vector3.UP * randf_range(-0.3, 0.5)).normalized()
		var twig_length = length * randf_range(0.12, 0.2)
		var twig = VineBuilder.build(twig_length, randf_range(-0.1, 0.1) * twig_length, 0.07 * (1.0 - 0.75 * along), 0.15, 0.03, randf() * TAU)
		VineBuilder.append_oriented(st, twig, dir * length * along, twig_dir, twig_length)
	var mesh = MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	scale = Vector3.ONE * 0.05
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, EXTEND_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(self, "scale", Vector3.ONE * 0.05, RETRACT_TIME).set_ease(Tween.EASE_IN)
	
