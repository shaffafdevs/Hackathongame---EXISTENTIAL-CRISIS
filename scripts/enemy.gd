class_name Enemy
extends CharacterBody2D

## A slime enemy. Patrols back and forth, chases the player when close, damages
## the player on contact and can be killed with the sword.

signal died

const MAX_HEALTH := 3
const PATROL_SPEED := 30.0
const CHASE_SPEED := 55.0
const DETECT_RANGE := 95.0
const DETECT_HEIGHT := 20.0
const CONTACT_DAMAGE := 1
const CONTACT_COOLDOWN := 0.8
const KNOCKBACK_X := 150.0
const KNOCKBACK_Y := -140.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: HealthBar = $HealthBar
@onready var damage_area: Area2D = $DamageArea
@onready var wall_ray: RayCast2D = $WallRay
@onready var floor_ray: RayCast2D = $FloorRay
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

var health: int = MAX_HEALTH

var _dir: int = -1
var _is_dying: bool = false
var _flash: float = 0.0
var _damage_cooldown: float = 0.0
var _lost_timer: float = 0.0
var _turn_lock: float = 0.0
var _player: Node2D = null


func _ready() -> void:
	health_bar.set_health(health, MAX_HEALTH)
	damage_area.body_entered.connect(_on_damage_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _is_dying:
		velocity.x = move_toward(velocity.x, 0.0, PATROL_SPEED)
		move_and_slide()
		return

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(1.0, 0.35, 0.35)
	elif sprite.modulate != Color(1.0, 1.0, 1.0):
		sprite.modulate = Color(1.0, 1.0, 1.0)

	if _lost_timer > 0.0:
		_lost_timer -= delta
	if _turn_lock > 0.0:
		_turn_lock -= delta

	var speed := PATROL_SPEED
	var chasing := false
	var desired_dir := _dir
	_player = _find_player()
	if _player != null and _lost_timer <= 0.0:
		var dx: float = _player.global_position.x - global_position.x
		var dy: float = _player.global_position.y - global_position.y
		if absf(dx) < DETECT_RANGE and absf(dy) < DETECT_HEIGHT:
			chasing = true
			speed = CHASE_SPEED
			if absf(dx) > 2.0:
				desired_dir = 1 if dx > 0.0 else -1

	# Look ahead so we never walk into a wall or off a ledge.
	wall_ray.position = Vector2(desired_dir * 6.0, -4.0)
	wall_ray.target_position = Vector2(desired_dir * 10.0, 0.0)
	wall_ray.force_raycast_update()
	floor_ray.position = Vector2(desired_dir * 8.0, 0.0)
	floor_ray.target_position = Vector2(0.0, 16.0)
	floor_ray.force_raycast_update()

	_dir = desired_dir
	if wall_ray.is_colliding() or not floor_ray.is_colliding():
		if chasing:
			# Cannot reach the player from here: patrol for a while instead.
			_lost_timer = 1.2
			speed = 0.0
		elif _turn_lock <= 0.0:
			# Hysteresis keeps the slime from jittering back and forth on a ledge.
			_dir = -desired_dir
			_turn_lock = 0.5

	velocity.x = _dir * speed
	sprite.flip_h = _dir < 0

	if absf(velocity.x) > 1.0:
		if sprite.animation != "move":
			sprite.play("move")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

	move_and_slide()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dying:
		return

	health = maxi(health - amount, 0)
	health_bar.set_health(health, MAX_HEALTH)
	_flash = 0.18

	if hurt_sound.stream != null:
		hurt_sound.play()

	var push := 1
	if from_position != Vector2.ZERO and absf(global_position.x - from_position.x) > 0.01:
		push = 1 if global_position.x > from_position.x else -1
	velocity.x = push * KNOCKBACK_X
	if is_on_floor():
		velocity.y = KNOCKBACK_Y

	if health <= 0:
		_die()


func _find_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null


func _on_damage_area_body_entered(body: Node2D) -> void:
	if _is_dying or _damage_cooldown > 0.0:
		return
	if body.has_method("take_damage"):
		_damage_cooldown = CONTACT_COOLDOWN
		body.take_damage(CONTACT_DAMAGE, global_position)


func _die() -> void:
	_is_dying = true
	damage_area.set_deferred("monitoring", false)
	set_collision_layer_value(3, false)
	health_bar.visible = false
	sprite.modulate = Color(1.0, 1.0, 1.0)
	sprite.play("death")

	if death_sound.stream != null:
		death_sound.play()

	died.emit()
	await get_tree().create_timer(0.7).timeout
	queue_free()