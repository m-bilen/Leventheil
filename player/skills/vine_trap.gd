extends Area3D

const ROOT_DURATION = 3.0
const SPROUT_TIME = 0.25
const SNAP_TIME = 0.12
const TENDRIL_COUNT = 8
const GROUND_OFFSET = -0.28
const BIND_RADIUS = 1.5


@export var material: Material

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	Events.wave_started.connect(_on_wave_started)
	build_tendrils()
	scale = Vector3.ONE * 0.05
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, SPROUT_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("root"):
		return
	var caught = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("root"):
			continue
		var offset = enemy.global_position - global_position
		offset.y = 0
		if offset.length() <= BIND_RADIUS:
			enemy.root(ROOT_DURATION)
			caught += 1
	Events.vine_trap_sprung.emit(global_position, caught)
	set_deferred("monitoring", false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.05, SNAP_TIME)
	tween.tween_callback(queue_free)

func _on_wave_started(_number: int) -> void:
	queue_free()

func build_tendrils() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in TENDRIL_COUNT:
		var a = TAU * i / TENDRIL_COUNT + randf_range(-0.3, 0.3)
		var outward = Vector3(cos(a), 0.0, sin(a))
		var start = outward * randf_range(0.05, 0.2)
		var dir = (outward + Vector3.UP * randf_range(0.8, 1.5)).normalized()
		var length = randf_range(0.7, 1.1)
		var tendril = VineBuilder.build(length, randf_range(0.08, 0.18) * length, 0.09, 0.15, 0.04, randf() * TAU)
		VineBuilder.append_oriented(st, tendril, start, dir, length)
	var mesh = MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position.y = GROUND_OFFSET
	add_child(mesh)
