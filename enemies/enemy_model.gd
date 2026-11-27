class_name EnemyModel
extends Node3D

const FlashMaterial = preload("res://enemies/flash_material.tres")
@export var eyes: Array[MeshInstance3D] = []
@export var root_vines: Node3D

var eye_material: StandardMaterial3D
var parts: Array[Node] = []
var moving = false


func _ready() -> void:
	if not eyes.is_empty():
		eye_material = eyes[0].material_override.duplicate()
		for eye in eyes:
			eye.material_override = eye_material
	parts = find_children("*", "MeshInstance3D", true, false)

func set_spirit(_color: Color) -> void:
	pass

func set_color(color: Color) -> void:
	eye_material.albedo_color = color
	eye_material.emission = color

func set_flash(on: bool) -> void:
	for part in parts:
		if on:
			if part.material_overlay != FlashMaterial:
				part.set_meta("base_overlay", part.material_overlay)
			part.material_overlay = FlashMaterial
		else:
			part.material_overlay = part.get_meta("base_overlay", null)

func set_rooted(on: bool) -> void:
	if root_vines and root_vines.has_method("bind"):
		root_vines.bind(on)
	elif root_vines:
		root_vines.visible = on

func set_moving(on: bool) -> void:
	moving = on

enum Pose { IDLE, WINDUP, OPEN, SLAM, STRIKE, RECOVER, STUNNED, PUSH, SHOVE, CROUCH, LUNGE}
var pose: Pose = Pose.IDLE

func set_pose(new_pose: Pose) -> void:
	pose = new_pose
	_on_pose_changed(new_pose)

func _on_pose_changed(_new_pose: Pose) -> void:
	pass

func get_head_point() -> Vector3:
	return global_position + Vector3.UP * 2.0
