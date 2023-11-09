extends CharacterBody3D

signal healthChanged(change)

const SPEED: float = 10.0
const JUMP_VELOCITY: float = 10

@onready var camera: Camera3D = $Camera3D
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var flash = $Camera3D/gun/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

@export var lookSensitivity: float = 0.005
@export var health: float = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = 20

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * lookSensitivity)
		camera.rotate_x(-event.relative.y * lookSensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if Input.is_action_just_pressed("shoot") and animations.current_animation != "shoot":
		shoot.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receiveDamage.rpc_id(hit_player.get_multiplayer_authority())
			

@rpc("call_local")
func shoot():
	animations.stop()
	animations.play("shoot")
	flash.restart()
	flash.emitting = true

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if animations.current_animation != "shoot":
		if input_dir != Vector2.ZERO and is_on_floor():
			animations.play("move")
		else:
			animations.play("idle")

	move_and_slide()

@rpc("any_peer")
func receiveDamage():
	health -= 1
	if health <= 0:
		position = Vector3.ZERO
		health = 3
	healthChanged.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		animations.play("idle")
