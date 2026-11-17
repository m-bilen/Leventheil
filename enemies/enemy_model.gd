class_name EnemyModel
extends Node

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

func get_base_color() -> Color:
	return eye_material.emission

func set_color(color: Color) -> void:
	eye_material.albedo_color = color
	eye_material.emission = color

func set_flash(on: bool) -> void:
	var overplay = FlashMaterial if on else null
	for part in parts:
		part.material_overlay = overplay

func set_rooted(on: bool) -> void:
	if root_vines:
		root_vines.visible = on

func set_moving(on: bool) -> void:
	moving = on

enum Pose { IDLE, WINDUP, OPEN, SLAM, STRIKE, RECOVER, STUNNED}
var pose: Pose = Pose.IDLE

func set_pose(new_pose: Pose) -> void:
	pose = new_pose
	_on_pose_changed(new_pose)

func _on_pose_changed(_new_pose: Pose) -> void:
	pass
