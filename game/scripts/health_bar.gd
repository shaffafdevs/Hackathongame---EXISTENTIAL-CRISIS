class_name HealthBar
extends Control

## A compact pixel-style health bar. Usable in world space (enemies) and in the
## HUD (player). Colour shifts from green to yellow to red as health drops.

@export var bar_width: float = 20.0
@export var bar_height: float = 4.0

@onready var _background: ColorRect = $Background
@onready var _fill: ColorRect = $Fill


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.size = Vector2(bar_width, bar_height)


func set_health(current: float, maximum: float) -> void:
	var ratio: float = 0.0
	if maximum > 0.0:
		ratio = clampf(current / maximum, 0.0, 1.0)

	_fill.size = Vector2((bar_width - 2.0) * ratio, bar_height - 2.0)

	if ratio > 0.5:
		_fill.color = Color("4fc44f")
	elif ratio > 0.25:
		_fill.color = Color("e8c341")
	else:
		_fill.color = Color("e0483a")