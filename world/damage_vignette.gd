extends ColorRect
const FLASH_TIME = 0.4
const LOW_HEALTH_RATIO = 0.4
const SHIELD_FLASH_TIME = 0.25

var shield_tween: Tween
var last_health = -1
var shader_material: ShaderMaterial
var tween: Tween

func _ready() -> void:
	shader_material = material
	Events.player_health_changed.connect(_on_health_changed)
	Events.player_shielded.connect(_on_shielded)

func _on_shielded() -> void:
	if shield_tween:
		shield_tween.kill()
	shield_tween = create_tween()
	shield_tween.set_ignore_time_scale(true)
	shield_tween.tween_method(set_shield_flash, 1.0, 0.0, SHIELD_FLASH_TIME)

func set_shield_flash(value: float) -> void:
	shader_material.set_shader_parameter("shield_flash", value)
 
func _on_health_changed(health: int, max_health: int) -> void:
	if last_health >= 0 and health < last_health:
		flash()
	last_health = health
	var ratio = float(health) / max_health
	shader_material.set_shader_parameter("low_health", clamp(1.0 - ratio / LOW_HEALTH_RATIO, 0.0, 1.0))

func flash() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_method(set_flash, 1.0, 0.0, FLASH_TIME)

func set_flash(value: float) -> void:
	shader_material.set_shader_parameter("flash", value)
