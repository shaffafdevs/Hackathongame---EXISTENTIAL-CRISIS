class_name Player
extends CharacterBody2D

## The knight. Moves, jumps, swings a sword, takes damage and can be buffed by
## the speed shard artifact.

signal health_changed(current: int, maximum: int)
signal boost_changed(active: bool, time_left: float)
signal died

const MAX_HEALTH := 5
const SPEED := 130.0
const JUMP_VELOCITY := -300.0

const ATTACK_DAMAGE := 1
const ATTACK_COOLDOWN := 0.4

const INVULN_TIME := 1.0
const HURT_KNOCKBACK := 210.0
const HURT_KNOCKBACK_Y := -150.0

const BOOST_SPEED_BONUS := 115.0
const BOOST_JUMP_BONUS := -80.0

const SWORD_REST_DEG := -25.0
const SWORD_WINDUP_DEG := -125.0
const SWORD_SWING_DEG := 55.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_pivot: Node2D = $SwordPivot
@onready var slash: AnimatedSprite2D = $Slash
@onready var hitbox: Area2D = $SwordHitbox
@onready var attack_window: Timer = $SwordHitbox/AttackWindow
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

var health: int = MAX_HEALTH
var facing: int = 1
var is_dead: bool = false
var boost_time: float = 0.0

var _attack_cooldown: float = 0.0
var _invuln: float = 0.0
var _flash: float = 0.0


func _ready() -> void:
	add_to_group("player")
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	attack_window.timeout.connect(_on_attack_window_timeout)
	slash.animation_finished.connect(func() -> void: slash.visible = false)
	slash.visible = false
	sword_pivot.rotation = deg_to_rad(SWORD_REST_DEG)
	sword_pivot.scale.x = facing
	health_changed.emit(health, MAX_HEALTH)


func _physics_process(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _invuln > 0.0:
		_invuln -= delta
	if _flash > 0.0:
		_flash -= delta

	if boost_time > 0.0:
		boost_time -= delta
		if boost_time <= 0.0:
			boost_time = 0.0
			boost_changed.emit(false, 0.0)
		else:
			boost_changed.emit(true, boost_time)

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		move_and_slide()
		return

	var speed := SPEED
	var jump_velocity := JUMP_VELOCITY
	if boost_time > 0.0:
		speed += BOOST_SPEED_BONUS
		jump_velocity += BOOST_JUMP_BONUS

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Run left/right: returns -1, 0 or 1
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	# Attack
	if Input.is_action_just_pressed("attack"):
		_attack()

	_update_animation(direction)
	_update_sprite_tint()
	move_and_slide()


func apply_boost(duration: float) -> void:
	boost_time = maxf(boost_time, duration)
	boost_changed.emit(true, boost_time)


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or _invuln > 0.0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	_invuln = INVULN_TIME
	_flash = 0.25

	if hurt_sound.stream != null:
		hurt_sound.play()

	if from_position != Vector2.ZERO:
		var push := 1
		if absf(global_position.x - from_position.x) > 0.01:
			push = 1 if global_position.x > from_position.x else -1
		velocity.x = push * HURT_KNOCKBACK
		velocity.y = HURT_KNOCKBACK_Y

	if health <= 0:
		_die()


func _attack() -> void:
	if is_dead or _attack_cooldown > 0.0:
		return

	_attack_cooldown = ATTACK_COOLDOWN
	slash.visible = false
	hitbox.monitoring = false

	var tween := create_tween()
	tween.tween_property(sword_pivot, "rotation", deg_to_rad(SWORD_WINDUP_DEG), 0.07)
	tween.tween_callback(_begin_swing)
	tween.tween_property(sword_pivot, "rotation", deg_to_rad(SWORD_SWING_DEG), 0.13) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "rotation", deg_to_rad(SWORD_REST_DEG), 0.15)


func _begin_swing() -> void:
	slash.visible = true
	slash.flip_h = facing < 0
	slash.position = Vector2(9.0 * facing, -4.0)
	slash.play("slash")

	hitbox.position = Vector2(12.0 * facing, -6.0)
	hitbox.monitoring = true
	attack_window.start()


func _on_attack_window_timeout() -> void:
	hitbox.monitoring = false


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(ATTACK_DAMAGE, global_position)


func _update_animation(direction: float) -> void:
	sprite.flip_h = facing < 0
	sword_pivot.scale.x = facing

	if not is_on_floor():
		sprite.play("idle")
	elif absf(direction) > 0.01:
		sprite.play("run")
	else:
		sprite.play("idle")


func _update_sprite_tint() -> void:
	var alpha := 1.0
	if _invuln > 0.0:
		alpha = 0.35 if fmod(_invuln, 0.2) < 0.1 else 1.0

	if _flash > 0.0:
		sprite.modulate = Color(1.0, 0.35, 0.35, alpha)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, alpha)


func _die() -> void:
	is_dead = true
	hitbox.monitoring = false
	slash.visible = false
	health_changed.emit(0, MAX_HEALTH)
	died.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "rotation", deg_to_rad(80.0 * facing), 0.5)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.8)

	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()