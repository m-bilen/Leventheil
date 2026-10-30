class_name EnemyBase
extends CharacterBody3D

const FLASH_TIME = 0.1

@export var max_health: int = 3
@export var pullable: bool = true

var pull_timer = 0.0
var pull_velocity = Vector3.ZERO
var root_timer = 0.0
var health: int
var player: Node3D
var base_color = Color.WHITE
var current_color = Color.WHITE
var flash_timer = 0.0

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health 
	player = get_tree().get_first_node_in_group("player")
	if mesh:
		mesh.mesh = mesh.mesh.duplicate()
		mesh.mesh.material = mesh.mesh.material.duplicate()
		base_color = mesh.mesh.material.albedo_color
	current_color = base_color

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	if is_rooted():
		amount *= 2
	health -= amount
	flash()
	_on_damaged()
	if health <= 0:
		die()

func _on_damaged() -> void:
	pass

func interrupt() -> void:
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
	_apply_color(color)

func flash() -> void:
	flash_timer = FLASH_TIME
	_apply_flash(true)


func _process(delta: float) -> void:
	if root_timer > 0.0:
		root_timer -= delta
		if root_timer <= 0.0:
			_apply_rooted(false)
	if pull_timer > 0.0:
		pull_timer -= delta
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			_apply_flash(false)


func root(duration: float) -> void:
	root_timer = max(root_timer, duration)
	_apply_rooted(true)

func is_rooted() -> bool:
	return root_timer > 0.0

func pull(to: Vector3, duration: float) -> void:
	var offset = to - global_position
	offset.y = 0
	pull_velocity = offset / duration
	pull_timer = duration
	interrupt()

func apply_status_effects() -> void:
	if pull_timer > 0.0:
		velocity.x = pull_velocity.x
		velocity.z = pull_velocity.z
	elif is_rooted():
		velocity.x = 0
		velocity.z = 0

func _apply_color(color: Color) -> void:
	if flash_timer > 0.0:
		return
	mesh.mesh.material.albedo_color = color

func _apply_rooted(on: bool) -> void:
	mesh.mesh.material.emission_enabled = on
	if on:
		mesh.mesh.material.emission = Color(0.1, 0.7, 0.2)

func _apply_flash(on: bool) -> void:
	mesh.mesh.material.albedo_color = Color.WHITE if on else current_color
