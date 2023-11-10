extends Node

@onready var mainMenu = $CanvasLayer/MainMenu
@onready var baseMenu = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/BaseMenu
@onready var hostMenu = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Hosting
@onready var joinMenu = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Joining
@onready var addressEntry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Joining/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var healthbar = $CanvasLayer/HUD/HealthBar
@onready var upnpEnabled = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Hosting/upnpCheck

const Player = preload("res://Prefabs/player.tscn")
const PORT = 25565
var enet_peer = ENetMultiplayerPeer.new()

@export var spawnpoint: Vector3 = Vector3(0, 6.376, 0)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_join_pressed():
	baseMenu.hide()
	joinMenu.show()

func _on_back_pressed_2(): #For join menu
	joinMenu.hide()
	baseMenu.show()

func _on_host_pressed():
	baseMenu.hide()
	hostMenu.show()

func _on_back_pressed_1(): #For host menu
	hostMenu.hide()
	baseMenu.show()

func _on_host_button_pressed():
	mainMenu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(addPlayer)
	multiplayer.peer_disconnected.connect(removePlayer)
	addPlayer(multiplayer.get_unique_id())
	if upnpEnabled.button_pressed:
		upnpSetup()

func _on_join_button_pressed():
	if addressEntry.text == "": return
	mainMenu.hide()
	hud.show()
	
	enet_peer.create_client(addressEntry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func addPlayer(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	player.position = spawnpoint
	add_child(player)
	if player.is_multiplayer_authority():
		player.healthChanged.connect(updateHealthBar)

func removePlayer(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func updateHealthBar(health):
	healthbar.value = health

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.healthChanged.connect(updateHealthBar)

func upnpSetup():
	var upnp = UPNP.new()
	var discoverResult = upnp.discover()
	assert(discoverResult == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discoverResult)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	var mapResult = upnp.add_port_mapping(PORT)
	assert(mapResult == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % mapResult)
	print("Success! Join Address: %s" % upnp.query_external_address())


