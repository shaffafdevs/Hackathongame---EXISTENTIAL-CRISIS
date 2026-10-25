extends Node2D

## Wires the player's health and boost signals to the on-screen HUD.

@onready var player: Player = $player
@onready var health_bar: HealthBar = $HUD/PlayerHealth
@onready var boost_label: Label = $HUD/BoostLabel


func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.boost_changed.connect(_on_player_boost_changed)
	health_bar.set_health(player.health, Player.MAX_HEALTH)
	boost_label.visible = false


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.set_health(current, maximum)


func _on_player_boost_changed(active: bool, time_left: float) -> void:
	boost_label.visible = active
	if active:
		boost_label.text = "SPEED +%.0fs" % ceilf(time_left)