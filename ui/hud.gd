extends CanvasLayer

const HealthFull = preload("res://ui/icons/health_full.svg")
const HealthEmpty = preload("res://ui/icons/health_empty.svg")
const PIP_SIZE = Vector2(30, 30)
const INACTIVE = Color(1, 1, 1, 0.3)

@onready var health_row: HBoxContainer = $TopLeft/HealthRow
@onready var spike_icon: TextureRect = $TopLeft/StanceRow/SpikeIcon
@onready var spike_count: Label = $TopLeft/StanceRow/SpikeCount
@onready var vine_icon: TextureRect = $TopLeft/StanceRow/VineIcon
@onready var wave_label = $WaveLabel
var banner_tween: Tween

func _ready() -> void:
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.spikes_changed.connect(_on_spikes_changed)
	Events.wave_started.connect(_on_wave_started)
	Events.boss_spawned.connect(_on_boss_spawned)
	Events.ability_unlocked.connect(show_banner)
	Events.stance_changed.connect(_on_stance_changed)
	vine_icon.visible = false

func _on_player_health_changed(health: int, max_health: int) -> void:
	while health_row.get_child_count() < max_health:
		var pip = TextureRect.new()
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.custom_minimum_size = PIP_SIZE
		health_row.add_child(pip)
	for i in health_row.get_child_count():
		health_row.get_child(i).texture = HealthFull if i < health else HealthEmpty

func _on_spikes_changed(count: int) -> void:
	spike_count.text = str(count)

func _on_wave_started(number: int) -> void:
	show_banner("Wave " + to_roman(number))
func _on_boss_spawned(boss_name: String) -> void:
	show_banner(boss_name)

func show_banner(text: String) -> void:
	if text.begins_with("Vines"):
		vine_icon.visible = true
	if banner_tween:
		banner_tween.kill()
	wave_label.text = text
	wave_label.modulate.a = 1.0
	banner_tween = create_tween()
	banner_tween.tween_interval(1.5)
	banner_tween.tween_property(wave_label, "modulate:a", 0.0, 0.8)

func _on_stance_changed(spikes_active: bool) -> void:
	spike_icon.modulate = Color.WHITE if spikes_active else INACTIVE
	spike_count.modulate = spike_icon.modulate
	vine_icon.modulate = INACTIVE if spikes_active else Color.WHITE

func to_roman(n: int) -> String:
	var numerals = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return numerals[n] if n < numerals.size() else str(n)
