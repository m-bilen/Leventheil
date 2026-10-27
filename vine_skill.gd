extends Node3D

const VineTrapScene = preload("res://vine_trap.tscn")
const HITS_TO_ROOT = 3
const ROOT_DURATION = 2.0
const PULL_RANGE = 8.0
const PULL_TIME = 0.2
const TETHER_TIME = 1.0
const PULL_STOP_DISTANCE = 1.2
const AIM_CONE = 0.85

var is_active = false
var charges = {}

func _ready() -> void:
	get_parent().stance_toggled.connect(_on_stance_toggled)
	get_parent().attack_landed.connect(_on_attack_landed)
	get_parent().jump_pressed.connect(_on_jump_pressed)
	Events.enemy_died.connect(_on_enemy_died)

func _on_stance_toggled() -> void:
	is_active = not is_active
	charges.clear()
	if is_active:
		sprout_seeds()

func _on_attack_landed(target: Node3D) -> void:
	if not is_active:
		return
	if target.is_queued_for_deletion() or not target.has_method("root"):
		return
	var count = charges.get(target, 0) + 1
	if count >= HITS_TO_ROOT:
		target.root(ROOT_DURATION)
		charges.erase(target)
	else:
		charges[target] = count

func _on_enemy_died(enemy: Node3D) -> void:
	charges.erase(enemy)

func _on_jump_pressed(aim_dir: Vector3) -> void:
	if not is_active or aim_dir == Vector3.ZERO:
		return
	var target = find_aimed_enemy(aim_dir)
	if target == null:
		return
	var player_pos = get_parent().global_position
	var away = target.global_position - player_pos
	away.y = 0
	var stop_point = player_pos + away.normalized() * PULL_STOP_DISTANCE
	target.pull(stop_point, PULL_TIME)
	target.root(PULL_TIME + TETHER_TIME)

func find_aimed_enemy(aim_dir: Vector3) -> Node3D:
	var best = null
	var best_alignment = AIM_CONE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("pull") or not enemy.pullable:
			continue
		var to_enemy = enemy.global_position - get_parent().global_position
		to_enemy.y = 0
		var d = to_enemy.length()
		if d == 0.0 or d > PULL_RANGE:
			continue
		var alignment = aim_dir.dot(to_enemy / d)
		if alignment > best_alignment:
			best_alignment = alignment 
			best = enemy
	return best

func replaces_jump() -> bool:
	return is_active

func sprout_seeds() -> void:
	for seed in get_tree().get_nodes_in_group("seeds"):
		var trap = VineTrapScene .instantiate()
		get_tree().current_scene.add_child(trap)
		trap.global_position = seed.global_position
		trap.global_position.y = 0.3
		seed.queue_free()
