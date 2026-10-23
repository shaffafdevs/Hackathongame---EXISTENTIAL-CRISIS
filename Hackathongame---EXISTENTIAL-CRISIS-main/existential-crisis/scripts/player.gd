extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -480.0
var gravity = 980.0
var gravity_dir = 1 # 1 = Normal, -1 = Inverted

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_dir * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * gravity_dir

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		$Sprite2D.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func flip_gravity() -> void:
	gravity_dir *= -1
	up_direction = Vector2(0, -gravity_dir)
	scale.y *= -1
