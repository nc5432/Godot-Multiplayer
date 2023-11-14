extends CharacterBody3D

signal healthChanged(change)

const SPEED: float = 10.0
const JUMP_VELOCITY: float = 10

@onready var camera: Camera3D = $Camera3D
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var flash = $Camera3D/gun/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var chickenModel = $chicken
@onready var nametag = $Username
@onready var syncronizer = $MultiplayerSynchronizer
@onready var gunshot = $Camera3D/gun/Gunshot
@onready var listener = $AudioListener3D
@onready var pauseMenu = $CanvasLayer/PauseMenu
@onready var world = $/root/World

@export var username: String = "Chicken"
@export var hat: int = 0
@export var lookSensitivity: float = 0.005
@export var health: float = 3

var syncTimer: int = 0
var hattified: bool = false
var paused: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = 20

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	chickenModel.hideMesh()
	nametag.hide()
	set_collision_layer_value(2, false)
	username = get_node("/root/World/CanvasLayer/MainMenu/MarginContainer/VBoxContainer/BaseMenu/Username:LineEdit").text
	if username == "": username = "Chicken"
	updateUsername()
	hat = get_node("/root/World/CanvasLayer/MainMenu/MarginContainer/VBoxContainer/BaseMenu/HatSelection:OptionButton").selected
	makeHat()
	listener.make_current()

func updateUsername():
	nametag.text = username

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("quit"):
		pause()
	if paused: return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * lookSensitivity)
		camera.rotate_x(-event.relative.y * lookSensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
	if Input.get_connected_joypads().size() > 0:
		var input_dir = Input.get_vector("lookLeft", "lookRight", "lookUp", "lookDown")
		rotate_y(-input_dir.x * lookSensitivity * 5)
		camera.rotate_x(-input_dir.y * lookSensitivity * 5)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
		
	if Input.is_action_just_pressed("shoot") and animations.current_animation != "shoot":
		shoot.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receiveDamage.rpc_id(hit_player.get_multiplayer_authority())
			

@rpc("call_local")
func shoot():
	animations.stop()
	animations.play("shoot")
	gunshot.play()
	flash.restart()
	flash.emitting = true

func _physics_process(delta):
	if not is_multiplayer_authority() or paused: return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
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

func _on_multiplayer_synchronizer_synchronized():
	if syncTimer > 5:
		if !hattified:
			makeHat()
			hattified = true
	else:
		syncTimer += 1

func makeHat():
	var hatPath: String = "res://Models/Hats/" + str(hat) + ".tscn"
	if ResourceLoader.exists(hatPath):
		var result = ResourceLoader.load(hatPath).instantiate()
		add_child(result)
		if is_multiplayer_authority():
			result.hideMesh()

func pause():
	if paused:
		pauseMenu.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		pauseMenu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = !paused

func _on_quit_pressed():
	get_tree().quit()

func _on_main_menu_pressed():
	world.enet_peer.disconnect()
	world.showMenu()
	queue_free()
