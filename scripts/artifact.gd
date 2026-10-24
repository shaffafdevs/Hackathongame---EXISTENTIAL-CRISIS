class_name SpeedShard
extends Area2D

## A floating physics shard. Touching it grants the player a temporary boost to
## both movement speed and jump height.

const BOOST_DURATION := 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_sound: AudioStreamPlayer = $PickupSound

var _time: float = 0.0
var _base_y: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	# Float up and down.
	position.y = _base_y + sin(_time * 2.5) * 3.0
	# Gentle sway and pulse.
	sprite.rotation = sin(_time * 1.8) * 0.18
	var pulse := 1.0 + sin(_time * 4.0) * 0.07
	sprite.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.has_method("apply_boost"):
		return
	body.apply_boost(BOOST_DURATION)
	_collect()


func _collect() -> void:
	_collected = true
	set_deferred("monitoring", false)
	if pickup_sound.stream != null:
		pickup_sound.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.9, 1.9), 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)