class_name EnemyBase
extends CharacterBody3D

const FLASH_TIME = 0.1

@export var max_health: int = 3

var health: int
var player: Node3D
var base_color = Color.WHITE
var current_color = Color.WHITE
var flash_timer = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("enemies")
	health = max_health 
	player = get_tree().get_first_node_in_group("player")
	mesh.mesh = mesh.mesh.duplicate()
	mesh.mesh.material = mesh.mesh.material.duplicate()
	base_color = mesh.mesh.material.albedo_color
	current_color = base_color

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	flash()
	_on_damaged()
	if health <= 0:
		die()

func _on_damaged() -> void:
	pass

func die() -> void:
	if is_queued_for_deletion():
		return 
	health = 0
	Events.enemy_died.emit(self)
	set_physics_process(false)
	queue_free()

func set_color(color: Color) -> void:
	current_color = color
	if flash_timer <= 0.0:
		mesh.mesh.material.albedo_color = color

func flash() -> void:
	flash_timer = FLASH_TIME 
	mesh.mesh.material.albedo_color = Color.WHITE

func _process(delta: float) -> void:
	if flash_timer <= 0.0:
		return
	flash_timer -= delta 
	if flash_timer <= 0.0:
		mesh.mesh.material.albedo_color = current_color
